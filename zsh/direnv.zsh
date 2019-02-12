if (( $+commands[direnv] )); then
    eval "$(direnv hook zsh)"
    direnv reload 2>/dev/null
fi
