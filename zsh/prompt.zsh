if [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
    . $ZSH/themes/powerlevel10k/powerlevel10k.zsh-theme

    if [[ $OSTYPE = WSL ]] && [[ $WSL_IS_ADMIN = 1 ]]; then
        add_wsl_admin() {
            RPROMPT="$RPROMPT [wsladmin]"
        }
        add-zsh-hook precmd add_wsl_admin
    fi
fi
