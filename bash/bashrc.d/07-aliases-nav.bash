# ==============================================================================
# 07-aliases-nav.bash — Navigation and filesystem aliases (portable)
# ==============================================================================

alias ~="cd ~"                   # Go to home directory
alias cd..='cd ../'              # Go up one directory (typo-safe)
alias ..='cd ../'                # Go up one directory
alias ...='cd ../../'            # Go up two directories
alias .3='cd ../../../'          # Go up three directories
alias .4='cd ../../../../'       # Go up four directories
alias .5='cd ../../../../../'    # Go up five directories
alias .6='cd ../../../../../../' # Go up six directories

alias cp='cp -iv'         # Interactive + verbose copy
alias mv='mv -iv'         # Interactive + verbose move
alias mkdir='mkdir -pv'   # Create parent dirs as needed, verbose
alias rsync='rsync -hvrP' # Human-readable, verbose, recursive, progress
alias pwd='pwd -P'        # Physical path (resolve symlinks)
alias du='du -sh'         # Summarize disk usage in human-readable form
alias c='clear'           # Clear terminal

alias microit='micro' # Open file in micro editor

# Edit dotfiles bash config (opens the bashrc.d/ module directory)
alias bashfig='${EDITOR:-vim} ~/.dotfiles/bash/'
# Reload bash config
alias bashsrc='source ~/.bashrc'

# Uncomment to enable:
# alias which='type -all'
# alias path='echo -e ${PATH//:/\\n}'  # Print PATH entries one per line
# alias show_options='shopt'
# alias fix_stty='stty sane'
# alias less='less -FSRXc'
