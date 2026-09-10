if [[ $TERM_PROGRAM == "WarpTerminal" ]]; then
    PROMPT='%n@%m %1~ %# '
    RPROMPT=
    return
fi

if (( $+commands[starship] )); then
    export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship-right.toml"
    eval "$(starship init zsh)"
else
    . "$ZDOTDIR/themes/powerlevel10k/powerlevel10k.zsh-theme"
fi
