# ==============================================================================
# os-darwin.bash — macOS-specific shell configuration
# ==============================================================================
# Sourced by bashrc only when OSTYPE matches darwin*.

# Suppress macOS Bash deprecation warning (macOS ships zsh as default since Catalina)
export BASH_SILENCE_DEPRECATION_WARNING=1

# BSD ls color format (macOS uses BSD ls, not GNU ls)
export LSCOLORS=GxFxCxDxBxegedabagaced

# Homebrew — supports both Apple Silicon (/opt/homebrew) and Intel (/usr/local)
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# ls aliases — BSD flags (-G = color, -F = type indicators, -h = human-readable)
alias ls='ls -GFhp'
alias ll='ls -lAGFhp'
alias lt='ls -lAGFhtr'
alias lg='ls -AGFhp'
alias l.='ls -dAGFhp .* 2>/dev/null'
alias lsize='ls -lAGFhpS'
alias lmodified='ls -lAGFhpt'
alias lall='ls -lAGFhpe'

# macOS-specific utilities
alias f='open -a Finder ./'
alias mysys='system_profiler SPSoftwareDataType SPHardwareDataType'
