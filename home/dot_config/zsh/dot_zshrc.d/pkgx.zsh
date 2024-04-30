if (( $+commands[pkgx] )); then
    pkgx_cache="$XDG_CACHE_HOME/zsh/pkgx.zsh"
    if [[ ! -e $pkgx_cache ]]; then
        mkdir -p $XDG_CACHE_HOME/zsh
        pkgx --shellcode >$pkgx_cache || rm -f $pkgx_cache
    fi
    source $pkgx_cache
    unset pkgx_cache
fi
