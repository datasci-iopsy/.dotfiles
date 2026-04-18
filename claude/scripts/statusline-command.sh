#!/usr/bin/env bash
# ~/.claude/scripts/statusline-command.sh
#
# Claude Code rich status line — pure bash + jq, zero extra deps.
# Receives Claude session JSON on stdin; prints a colored status line.
# Designed for dark-mode terminals. Compatible with macOS and Linux (Ubuntu/RHEL).
#
# Segments (left → right):
#   «session» · model · effort · [vim] · ctx% · tok · cache · cost ·
#   5h:[▓▓▓░░] pct% Xhm · 7d% · ⎇ branch +S ~M
#
# Fields not yet in the Claude JSON payload (upstream feature requests):
#   - effort level  → read from ~/.claude/settings.json (updates on /effort)
#   - memory usage  → not exposed by Claude Code

command -v jq &>/dev/null || exit 0

input=$(cat)
printf '%s\n' "$input" | jq -e . &>/dev/null || exit 0

# ─── Locale: Unicode vs ASCII fallback ───────────────────────────────────────
if [[ "${LANG:-}${LC_ALL:-}${LC_CTYPE:-}" == *UTF-8* ]]; then
    BAR_F="█"; BAR_E="░"; WT_ICON="⎇ "; CENT="¢"
else
    BAR_F="#"; BAR_E="-"; WT_ICON="wt:"; CENT="c"
fi

# ─── ANSI — bright palette optimized for dark-mode terminals ─────────────────
rs=$'\033[0m'
dim=$'\033[2m'
bd=$'\033[1m'
ul=$'\033[4m'

b_cyn=$'\033[96m'      # model name         (bright cyan)
b_grn=$'\033[92m'      # low usage / clean  (bright green)
b_yel=$'\033[93m'      # medium / session   (bright yellow)
b_mag=$'\033[95m'      # rate limits        (bright magenta)
b_blu=$'\033[94m'      # git / cache        (bright blue)
b_red=$'\033[91m'      # high usage / warn  (bright red)
b_wht=$'\033[97m'      # misc / cost        (bright white)

SEP="${dim}·${rs}"

# ─── Parse Claude JSON in a single jq pass ───────────────────────────────────
# @sh quotes string values safely for eval; numerics are jq-computed integers.
_jq=$(printf '%s\n' "$input" | jq -r '
    "model_raw=\(.model.id // "" | @sh)",
    "cwd_j=\(.workspace.current_dir // .cwd // "" | @sh)",
    "ctx_pct=\(.context_window.used_percentage // 0 | floor)",
    "in_tok=\(.context_window.current_usage.input_tokens // 0)",
    "out_tok=\(.context_window.current_usage.output_tokens // 0)",
    "cache_r=\(.context_window.current_usage.cache_read_input_tokens // 0)",
    "five_pct=\(.rate_limits.five_hour.used_percentage // 0 | floor)",
    "five_resets=\(.rate_limits.five_hour.resets_at // 0)",
    "week_pct=\(.rate_limits.seven_day.used_percentage // 0 | floor)",
    "cost_usd=\(.cost.total_cost_usd // 0)",
    "vim_mode=\(.vim.mode // "" | @sh)",
    "wt_name=\(.workspace.git_worktree // .worktree.name // "" | @sh)"
' 2>/dev/null)
[ -z "$_jq" ] && exit 0
eval "$_jq" 2>/dev/null || exit 0

cwd="${cwd_j:-$PWD}"

# Effort level: read from settings.json (reflects /effort changes immediately
# because settings.json is rewritten on each change and we re-read each refresh)
effort=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)

# ─── Helpers ─────────────────────────────────────────────────────────────────

# "claude-sonnet-4-6-20251001" → "sonnet-4.6"
shorten_model() {
    local s="${1#claude-}"
    s=$(printf '%s' "$s" | sed 's/-[0-9]\{8\}$//')
    s=$(printf '%s' "$s" | sed 's/-\([0-9][0-9]*\)$/.\1/')
    printf '%s' "$s"
}

# 12345 → "12k",  999 → "999"
fmt_k() {
    local n=${1:-0}
    if [ "$n" -ge 1000 ] 2>/dev/null; then
        printf '%dk' "$(( n / 1000 ))"
    else
        printf '%d' "$n"
    fi
}

# Colored progress bar: filled chars in usage-appropriate color, empties dimmed
progress_bar() {
    local pct=$1 width=${2:-8}
    local filled=$(( pct * width / 100 ))
    [ "$filled" -gt "$width" ] && filled=$width
    local empty=$(( width - filled ))

    # Fill color tracks urgency
    local fill_col
    if   [ "$pct" -ge 80 ]; then fill_col="${b_red}${bd}"
    elif [ "$pct" -ge 60 ]; then fill_col="${b_yel}"
    else                          fill_col="${b_grn}"
    fi

    local bar="" i
    for (( i=0; i<filled; i++ )); do bar+="${fill_col}${BAR_F}${rs}"; done
    for (( i=0; i<empty;  i++ )); do bar+="${dim}${BAR_E}${rs}";      done
    printf '%s' "$bar"
}

# Return ANSI prefix for a 0-100 percentage: green < 60, yellow < 80, red+bold
pct_color() {
    if   [ "${1:-0}" -ge 80 ] 2>/dev/null; then printf '%s' "${b_red}${bd}"
    elif [ "${1:-0}" -ge 60 ] 2>/dev/null; then printf '%s' "${b_yel}"
    else                                         printf '%s' "${b_grn}"
    fi
}

# ─── Build segments ───────────────────────────────────────────────────────────
segs=()

# ── Model ─────────────────────────────────────────────────────────────────────
if [ -n "$model_raw" ]; then
    segs+=("$(printf "${b_cyn}${bd}%s${rs}" "$(shorten_model "$model_raw")")")
fi

# ── Effort level (from settings.json) ─────────────────────────────────────────
# Symbols: ↓ low  ▶ medium  ↑ high  — colored to match urgency
if [ -n "$effort" ]; then
    case "$effort" in
        low)    segs+=("$(printf "${b_grn}${dim}↓low${rs}")")    ;;
        medium) segs+=("$(printf "${b_yel}${dim}▶med${rs}")")    ;;
        high)   segs+=("$(printf "${b_red}${bd}↑high${rs}")")    ;;
        *)      segs+=("$(printf "${dim}%s${rs}" "$effort")")     ;;
    esac
fi

# ── Vim mode (only when enabled) ──────────────────────────────────────────────
if [ -n "$vim_mode" ]; then
    segs+=("$(printf "${dim}[%s]${rs}" "$vim_mode")")
fi

# ── Context window % (label+value colored together by threshold) ──────────────
if [ "${ctx_pct:-0}" -gt 0 ] 2>/dev/null; then
    col=$(pct_color "$ctx_pct")
    segs+=("$(printf "${col}ctx:%d%%${rs}" "$ctx_pct")")
fi

# ── Token counts: input + output ──────────────────────────────────────────────
if [ "${in_tok:-0}"  -gt 0 ] 2>/dev/null &&
   [ "${out_tok:-0}" -gt 0 ] 2>/dev/null; then
    segs+=("$(printf "${b_grn}${dim}%s${b_wht}${dim}+%s${rs}" \
        "$(fmt_k "$in_tok")" "$(fmt_k "$out_tok")")")
fi

# ── Cache reads (only when substantial; saves visual noise early on) ──────────
if [ "${cache_r:-0}" -ge 1000 ] 2>/dev/null; then
    segs+=("$(printf "${b_blu}${dim}cache:%s${rs}" "$(fmt_k "$cache_r")")")
fi

# ── Session cost ──────────────────────────────────────────────────────────────
if [ "${cost_usd:-0}" != "0" ]; then
    cost_str=$(awk -v c="$cost_usd" -v cent="$CENT" 'BEGIN {
        v = c + 0
        if (v <= 0)        { exit }
        else if (v < 0.01) { printf "<1%s", cent }
        else               { printf "$%.2f", v }
    }' 2>/dev/null)
    [ -n "$cost_str" ] && segs+=("$(printf "${b_wht}${dim}%s${rs}" "$cost_str")")
fi

# ── 5-hour block: colored progress bar + pct + time until reset ──────────────
if [ "${five_pct:-0}" -gt 0 ] 2>/dev/null; then
    bar=$(progress_bar "$five_pct" 8)
    col=$(pct_color "$five_pct")

    time_str=""
    if [ "${five_resets:-0}" -gt 0 ] 2>/dev/null; then
        now=$(date +%s 2>/dev/null)
        if [ -n "$now" ]; then
            remaining=$(( five_resets - now ))
            if [ "$remaining" -gt 0 ]; then
                hrs=$(( remaining / 3600 ))
                mins=$(( (remaining % 3600) / 60 ))
                if [ "$hrs" -gt 0 ]; then
                    time_str=" ${dim}${hrs}h${mins}m${rs}"
                else
                    time_str=" ${dim}${mins}m${rs}"
                fi
            fi
        fi
    fi

    segs+=("$(printf "${col}5h:[%s${col}]%d%%%s${rs}" \
        "$bar" "$five_pct" "$time_str")")
fi

# ── 7-day rate limit ──────────────────────────────────────────────────────────
if [ "${week_pct:-0}" -gt 0 ] 2>/dev/null; then
    col=$(pct_color "$week_pct")
    segs+=("$(printf "${col}${dim}7d:%d%%${rs}" "$week_pct")")
fi

# ── Git: branch + worktree indicator + staged/modified counts ────────────────
if command -v git &>/dev/null; then
    branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then

        # Worktree: JSON field first; fall back to git-dir comparison
        is_wt=false
        if [ -n "$wt_name" ]; then
            is_wt=true
        else
            _gd=$(git -C "$cwd" rev-parse --git-dir        2>/dev/null)
            _gc=$(git -C "$cwd" rev-parse --git-common-dir 2>/dev/null)
            [ -n "$_gd" ] && [ "$_gd" != "$_gc" ] && is_wt=true
        fi

        # Dirty counts — -uno skips untracked scan for speed on large repos
        staged=0; modified=0
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            x="${line:0:1}"; y="${line:1:1}"
            [[ "$x" != " " && "$x" != "?" ]] && (( staged++ ))
            [[ "$y" != " " && "$y" != "?" ]] && (( modified++ ))
        done < <(git -C "$cwd" status --porcelain -uno 2>/dev/null)

        prefix=""
        [ "$is_wt" = "true" ] && prefix="${b_mag}${dim}${WT_ICON}${rs}"

        dirty=""
        [ "$staged"   -gt 0 ] && dirty+=" ${b_grn}+${staged}${rs}"
        [ "$modified" -gt 0 ] && dirty+=" ${b_yel}~${modified}${rs}"

        segs+=("$(printf "${b_blu}%s${bd}%s${rs}%s" "$prefix" "$branch" "$dirty")")
    fi
fi

# ─── Render — segments joined by dim middot, wrapped in dim brackets ──────────
if [ "${#segs[@]}" -gt 0 ]; then
    bar=""
    for i in "${!segs[@]}"; do
        [ "$i" -eq 0 ] \
            && bar="${segs[$i]}" \
            || bar="${bar} ${SEP} ${segs[$i]}"
    done
    printf "${dim}[${rs}%s${dim}]${rs}" "$bar"
fi
