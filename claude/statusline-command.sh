#!/usr/bin/env bash
# ~/.claude/statusline-command.sh
#
# Claude Code rich status bar.
# Receives Claude session JSON on stdin; outputs a compact colored status line.
# Fails silently when jq is unavailable or input is malformed.

# Require jq; exit silently if missing.
command -v jq &>/dev/null || exit 0

# Read and parse stdin; exit silently on malformed JSON.
input=$(cat)
echo "$input" | jq -e . &>/dev/null || exit 0

# ---------------------------------------------------------------------------
# ANSI helpers
# ---------------------------------------------------------------------------
reset=$'\033[0m'
dim=$'\033[2m'
bold=$'\033[1m'

cyan=$'\033[36m'       # model name
green=$'\033[32m'      # context / token info
yellow=$'\033[33m'     # cost
magenta=$'\033[35m'    # rate limits
blue=$'\033[34m'       # cache info
white=$'\033[37m'      # fallback / misc

sep="${dim}·${reset}"   # subtle segment separator

# ---------------------------------------------------------------------------
# Extract fields from JSON
# ---------------------------------------------------------------------------
model_raw=$(echo "$input"    | jq -r '.model.id // empty')
ctx_used=$(echo "$input"     | jq -r '.context_window.used_percentage // empty')
in_tok=$(echo "$input"       | jq -r '.context_window.current_usage.input_tokens // empty')
out_tok=$(echo "$input"      | jq -r '.context_window.current_usage.output_tokens // empty')
cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // empty')
cache_read=$(echo "$input"   | jq -r '.context_window.current_usage.cache_read_input_tokens // empty')
five_pct=$(echo "$input"     | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input"     | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ---------------------------------------------------------------------------
# Shorten model ID to a human-readable slug.
# e.g. "claude-sonnet-4-6-20251001" → "sonnet-4.6"
#      "claude-opus-4-5"            → "opus-4.5"
#      "claude-haiku-3-5-20240307"  → "haiku-3.5"
# Strategy: strip leading "claude-", strip trailing date suffix (-YYYYMMDD),
# then collapse the last two numeric parts with a dot.
# ---------------------------------------------------------------------------
shorten_model() {
    local id="$1"
    # Strip "claude-" prefix
    local s="${id#claude-}"
    # Strip trailing date suffix: -YYYYMMDD (8 digits)
    s=$(echo "$s" | sed 's/-[0-9]\{8\}$//')
    # The remaining form is e.g. "sonnet-4-6" or "opus-4" or "haiku-3-5"
    # Replace the last "-<digit>" pair with ".<digit>" to get "sonnet-4.6"
    s=$(echo "$s" | sed 's/-\([0-9][0-9]*\)$/.\1/')
    echo "$s"
}

# ---------------------------------------------------------------------------
# Build segments array — each element is a pre-colored string.
# Segments are only added when the underlying value is present and non-zero.
# ---------------------------------------------------------------------------
segments=()

# -- Model (cyan) -----------------------------------------------------------
if [ -n "$model_raw" ]; then
    model_short=$(shorten_model "$model_raw")
    segments+=("$(printf "${cyan}${bold}%s${reset}" "$model_short")")
fi

# -- Context window used % (green) ------------------------------------------
if [ -n "$ctx_used" ] && [ "$(printf '%.0f' "$ctx_used")" -gt 0 ] 2>/dev/null; then
    ctx_fmt=$(printf '%.0f' "$ctx_used")
    segments+=("$(printf "${green}ctx:%s%%${reset}" "$ctx_fmt")")
fi

# -- Token counts: input + output (green, dimmer) ---------------------------
# Show as "tok:12k+3k" (input+output) when both are present and non-zero.
if [ -n "$in_tok" ] && [ -n "$out_tok" ] \
   && [ "$in_tok" -gt 0 ] 2>/dev/null && [ "$out_tok" -gt 0 ] 2>/dev/null; then
    # Format numbers: show "k" suffix when >= 1000
    fmt_k() {
        local n=$1
        if [ "$n" -ge 1000 ] 2>/dev/null; then
            printf '%dk' "$(( n / 1000 ))"
        else
            printf '%d' "$n"
        fi
    }
    in_fmt=$(fmt_k "$in_tok")
    out_fmt=$(fmt_k "$out_tok")
    segments+=("$(printf "${green}${dim}tok:%s+%s${reset}" "$in_fmt" "$out_fmt")")
elif [ -n "$in_tok" ] && [ "$in_tok" -gt 0 ] 2>/dev/null; then
    fmt_k() { local n=$1; [ "$n" -ge 1000 ] 2>/dev/null && printf '%dk' "$(( n / 1000 ))" || printf '%d' "$n"; }
    segments+=("$(printf "${green}${dim}in:%s${reset}" "$(fmt_k "$in_tok")")")
fi

# -- Cache read tokens (blue) — only when meaningfully non-zero (>= 1000) ---
if [ -n "$cache_read" ] && [ "$cache_read" -ge 1000 ] 2>/dev/null; then
    cr_fmt=$(printf '%dk' "$(( cache_read / 1000 ))")
    segments+=("$(printf "${blue}${dim}cache:%s${reset}" "$cr_fmt")")
fi

# -- 5-hour rate limit (magenta) --------------------------------------------
if [ -n "$five_pct" ] && [ "$(printf '%.0f' "$five_pct")" -gt 0 ] 2>/dev/null; then
    five_fmt=$(printf '%.0f' "$five_pct")
    segments+=("$(printf "${magenta}5h:%s%%${reset}" "$five_fmt")")
fi

# -- 7-day rate limit (magenta, slightly dimmer) ----------------------------
if [ -n "$week_pct" ] && [ "$(printf '%.0f' "$week_pct")" -gt 0 ] 2>/dev/null; then
    week_fmt=$(printf '%.0f' "$week_pct")
    segments+=("$(printf "${magenta}${dim}7d:%s%%${reset}" "$week_fmt")")
fi

# ---------------------------------------------------------------------------
# Render — join segments with the dim separator, wrap in dim brackets.
# ---------------------------------------------------------------------------
if [ ${#segments[@]} -gt 0 ]; then
    # Join with " · "
    bar=""
    for i in "${!segments[@]}"; do
        if [ "$i" -eq 0 ]; then
            bar="${segments[$i]}"
        else
            bar="${bar} ${sep} ${segments[$i]}"
        fi
    done
    printf "${dim}[${reset}%s${dim}]${reset}" "$bar"
fi
