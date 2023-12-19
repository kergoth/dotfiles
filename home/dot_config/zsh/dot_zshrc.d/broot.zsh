if (( $commands[broot] )); then
    if ! [[ -e "$XDG_CACHE_HOME/zsh/functions/br" ]] || [[ $commands[broot] -nt "$XDG_CACHE_HOME/zsh/functions/br" ]]; then
        broot --print-shell-function zsh >"$XDG_CACHE_HOME/zsh/functions/br"
        broot --set-install-state installed
    fi
fi
