if (( $+commands[direnv] )); then
    direnv_cache="$XDG_CACHE_HOME/direnv/env.zsh"
    if [[ ! -e $direnv_cache ]]; then
        mkdir -p $XDG_CACHE_HOME/direnv
        direnv hook zsh >$direnv_cache || rm -f $direnv_cache
    fi
    source $direnv_cache
    unset direnv_cache

    direnv reload 2>/dev/null
fi
