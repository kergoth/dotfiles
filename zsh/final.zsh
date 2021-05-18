if (( $+commands[mcfly] )); then
    MCFLY_PATH="$(command -v mcfly)"

    mcfly_cache="$XDG_CACHE_HOME/mcfly/env.zsh"
    if [[ ! -e $mcfly_cache ]]; then
        mkdir -p $XDG_CACHE_HOME/mcfly
        mcfly init zsh >$mcfly_cache || rm -f $mcfly_cache
    fi
    source $mcfly_cache
    unset mcfly_cache
fi
