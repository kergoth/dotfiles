if (( ${+commands[direnv]} )); then
    if [ "$home_nix" = 1 ] && [ $commands[direnv] = $HOME/.nix/shims/direnv ]; then
        emulate zsh -c "$(nixrun direnv export zsh)"
    else
        emulate zsh -c "$(direnv export zsh)"
    fi
fi
