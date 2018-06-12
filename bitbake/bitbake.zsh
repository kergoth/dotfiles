alias bback='ack --type=bitbake'
alias newlayer=bbnewlayer

if (( $+commands[pt] )); then
    alias bbag="pt -G '\.(bb|bbappend|inc|conf)$'"
    alias bbs=bbag
elif (( $+commands[ag] )); then
    alias bbag="ag -G '\.(bb|bbappend|inc|conf)$'"
    alias bbs=bbag
elif (( $+commands[ack] )); then
    alias bback='ack --type=bitbake'
    alias bbag=bback
    alias bbs=bbag
fi
alias bbfd="fd -t f -e bb -e inc -e conf -e bbclass -e bbappend"
alias bbfdf="bbfd ''"

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
