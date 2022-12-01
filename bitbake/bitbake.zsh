vim_pager () {
    /usr/share/vim/*/macros/less.sh -
}

bbenv_pager () {
    if [[ -t 1 ]]; then
        if (( $+commands[bat] )); then
            bat -l BitBake "$@"
        else
            vim_pager "$@"
        fi
    else
        cat "$@"
    fi
}

bbenv () {
    bitbake -e "$@" | bbenv_pager
}

