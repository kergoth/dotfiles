if (( $+commands[mcfly] )); then
    MCFLY_PATH="$(command -v mcfly)"
    eval "$(mcfly init zsh)"
fi
