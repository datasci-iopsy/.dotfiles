# ==============================================================================
# 06-functions.bash — Shell functions
# ==============================================================================

# Make a directory and immediately cd into it
mcd() {
    mkdir -p "$1" && cd "$1"
}

# Uncomment to enable:
# trash() { command mv "$@" ~/.Trash; }        # Move to Trash instead of deleting
# ql()    { qlmanage -p "$*" >&/dev/null; }    # Quick Look a file from terminal (macOS)
# cd()    { builtin cd "$@"; ll; }             # Auto-list contents after cd
