# ==============================================================================
# 04-path.bash — PATH and package manager setup (portable)
# ==============================================================================

# pyenv — Python version management
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    # pyenv-virtualenv is optional; skip silently if not installed
    if pyenv commands 2>/dev/null | grep -q virtualenv-init; then
        eval "$(pyenv virtualenv-init -)"
    fi
fi

# pipx / uv tools — installed to ~/.local/bin
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# Google Cloud SDK
if [ -f "$HOME/google-cloud-sdk/path.bash.inc" ]; then
    . "$HOME/google-cloud-sdk/path.bash.inc"
fi
if [ -f "$HOME/google-cloud-sdk/completion.bash.inc" ]; then
    . "$HOME/google-cloud-sdk/completion.bash.inc"
fi

# Note: GOOGLE_CLOUD_PROJECT is machine-specific — set it in ~/.bashrc.local
