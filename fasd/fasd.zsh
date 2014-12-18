if (( $+commands[fasd] )); then
    fasd_cache="$XDG_DATA_HOME/fasd/env.zsh"
    if [[ ! -e $fasd_cache ]]; then
        mkdir -p $XDG_DATA_HOME/fasd
        fasd --init auto | sed 's,$,;,' >$fasd_cache
    fi
    source $fasd_cache
    unset fasd_cache

    if [[ $OSTYPE =~ darwin* ]]; then
        alias o="a -e open"
    else
        alias o="a -e xdg-open"
    fi
    alias v='f -t -e vim -b viminfo'
fi
