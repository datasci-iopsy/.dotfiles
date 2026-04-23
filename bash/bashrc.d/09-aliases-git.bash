# ==============================================================================
# 09-aliases-git.bash — Git aliases (portable)
# ==============================================================================

# Core operations
alias gst='git status'
alias gco='git checkout'
alias gcam='git commit -a'
alias gl='git pull --rebase'
alias gp='git push'
alias gd='git diff'
alias grb='git rebase'
alias gcp='git cherry-pick'

# Stash
alias gsta='git stash push'
alias gstl='git stash list'

# Batch operations
alias gaa='git add --all'
alias grh='git reset --hard'
alias gclean='git clean -fd'

# Pretty log graph
alias glog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"
