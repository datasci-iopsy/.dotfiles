# ==============================================================================
# 10-aliases-python.bash — Python aliases
# ==============================================================================

alias wipe_pip='pip freeze | cut -d "@" -f1 | xargs pip uninstall -y' # Uninstall all pip packages
