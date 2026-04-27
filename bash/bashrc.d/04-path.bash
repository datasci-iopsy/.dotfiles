# ==============================================================================
# 04-path.bash — PATH and package manager setup (portable)
# ==============================================================================

# pyenv — binary on PATH for legacy/work projects that need it via .envrc
# Personal projects use uv. To enable pyenv shims in a project, add to .envrc:
#   eval "$(pyenv init -)"
if [ -d "$HOME/.pyenv" ]; then
	export PYENV_ROOT="$HOME/.pyenv"
	export PATH="$PYENV_ROOT/bin:$PATH"
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
