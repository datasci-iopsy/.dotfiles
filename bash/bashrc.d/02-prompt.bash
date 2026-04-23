# ==============================================================================
# 02-prompt.bash — Custom prompt
# ==============================================================================

# Show hostname, current directory basename, and git branch (when inside a repo)
git_branch() {
    local dir_name branch_name
    dir_name=$(basename "$(pwd)")

    if git rev-parse --is-inside-work-tree &>/dev/null; then
        branch_name=$(git symbolic-ref --short -q HEAD)
        PS1="\[\e[1;32m\]\h\e[0m\]:\[\e[1;34m\][${dir_name}]\[\e[0m\]:\[\e[1;33m\]{${branch_name}}\[\e[0m\] "
    else
        PS1="\[\e[1;32m\]\h\e[0m\]:\[\e[1;34m\][${dir_name}]\[\e[0m\] "
    fi
}

PROMPT_COMMAND=git_branch
