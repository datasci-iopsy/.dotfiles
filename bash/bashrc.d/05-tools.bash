# ==============================================================================
# 05-tools.bash — Shell tool integrations
# ==============================================================================

# thefuck — corrects previous console commands
if command -v thefuck >/dev/null 2>&1; then
    eval "$(thefuck --alias)"
    eval "$(thefuck --alias FUCK)"
fi

# direnv — per-directory environment variables
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi
