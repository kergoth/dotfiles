alias newlayer=bbnewlayer

vim_pager () {
    /usr/share/vim/*/macros/less.sh -
}

bbenv_pager () {
    if [[ -t 1 ]]; then
        vim_pager -c 'au VimEnter * set ft=bitbake fdl=99' "$@"
    else
        cat
    fi
}

bbenv () {
    bitbake -e "$@" | bbenv_pager
}

bbenvvar () {
    local var="$1"
    shift
    bitbake -e "$@" | bbenv_pager -c "/^${var}[=(]"
}
