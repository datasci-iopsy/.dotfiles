# ==============================================================================
# os-linux.bash — Linux-specific shell configuration
# ==============================================================================
# Sourced by bashrc only when OSTYPE matches linux*.

# GNU ls color format (Linux uses GNU ls, not BSD ls)
# Equivalent colors to the macOS LSCOLORS setting.
export LS_COLORS='di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

# ls aliases — GNU flags (--color=auto replaces BSD -G)
alias ls='ls --color=auto -Fhp'
alias ll='ls --color=auto -lAFhp'
alias lt='ls --color=auto -lAFhtr'
alias lg='ls --color=auto -AFhp'
alias l.='ls --color=auto -dAFhp .* 2>/dev/null'
alias lsize='ls --color=auto -lAFhpS'
alias lmodified='ls --color=auto -lAFhpt'
alias lall='ls --color=auto -lAFhp'

# Linux-specific utilities
alias f='xdg-open . &>/dev/null'
alias mysys='uname -a; lsb_release -a 2>/dev/null'
