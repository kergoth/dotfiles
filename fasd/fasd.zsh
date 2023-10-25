if (( $+commands[fasd] )) && ! (( $+commands[zoxide] )); then
    fasd_cache="$XDG_CACHE_HOME/fasd/env.zsh"
    if [[ ! -e $fasd_cache ]]; then
        mkdir -p $XDG_CACHE_HOME/fasd
        fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install \
                    zsh-wcomp zsh-wcomp-install >$fasd_cache || rm -f $fasd_cache
    fi
    source $fasd_cache
    unset fasd_cache

    alias ff="fasd -f"
    unalias f
    unalias sd

    if [[ $OSTYPE =~ darwin* ]]; then
        alias o="a -e open"
    else
        alias o="a -e xdg-open"
    fi
    if (( $+commands[fzf] )); then
        _z_fzf () {
            if [[ $# -eq 0 ]]; then
                cd "$(fasd -d 2>&1 | fzf +s --tac | sed 's/^[0-9,.]* *//')"
            else
                fasd_cd -d "$@"
            fi
        }
        alias z=_z_fzf

        _v_fzf () {
            local file
            file="$(ff -t -l -b viminfo "$1" | fzf -1 -0 --no-sort --tac +m)" && vim "${file}" || return 1
        }
        alias v=_v_fzf
    else
        alias v='ff -t -e vim -b viminfo'
    fi
fi
