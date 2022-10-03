if (( ${+commands[direnv]} )); then
    if [ "$home_nix" = 1 ] && [ $commands[direnv] = $HOME/.nix/shims/direnv ]; then
        emulate zsh -c "$(nixrun direnv hook zsh | sed -e "s#\"/nix.*/direnv\"#nixrun direnv#g")"
    else
        emulate zsh -c "$(direnv hook zsh)"
    fi
fi
