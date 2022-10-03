if (( ${+commands[direnv]} )); then
    emulate zsh -c "$(direnv hook zsh)"
fi
