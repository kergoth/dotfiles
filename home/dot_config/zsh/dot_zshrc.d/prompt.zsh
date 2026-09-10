if (( $+commands[starship] )); then
    export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship-right.toml"
    eval "$(starship init zsh)"
elif [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
    . "$ZDOTDIR/themes/powerlevel10k/powerlevel10k.zsh-theme"
fi
