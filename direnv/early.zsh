if (( ${+commands[direnv]} )); then
    emulate zsh -c "$(direnv export zsh)"
fi
