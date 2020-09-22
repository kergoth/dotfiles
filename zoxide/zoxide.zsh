if (( $+commands[zoxide] )); then
    unalias z 2>/dev/null || :
    alias zz=zi

    zoxide_cache="$XDG_CACHE_HOME/zoxide.env.zsh"
    if [[ ! -e $zoxide_cache ]] || [[ $commands[zoxide] -nt "$zoxide_cache" ]]; then
        zoxide init zsh >$zoxide_cache
    fi
    source $zoxide_cache
    unset zoxide_cache
fi
