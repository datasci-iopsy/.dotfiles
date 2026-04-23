# ==============================================================================
# 01-shell-init.bash — Shell initialization
# ==============================================================================

# Source ~/.profile for login shells only (POSIX env vars, path additions)
if shopt -q login_shell 2>/dev/null && [ -r "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi
