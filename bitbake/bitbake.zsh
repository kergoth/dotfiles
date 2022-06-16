alias newlayer=bbnewlayer
alias bback='ack --type=bitbake'
alias bb-getvar=bitbake-getvar
alias bbgetvar=bitbake-getvar
alias bbenvvar=bitbake-getvar

if (( $+commands[rg] )); then
    alias bbrg="rg -t bitbake"
    alias bbg=bbrg
elif (( $+commands[pt] )); then
    alias bbag="pt -G '\.(bb|bbappend|inc|conf)$'"
    alias bbg=bbag
elif (( $+commands[ag] )); then
    alias bbag="ag -G '\.(bb|bbappend|inc|conf)$'"
    alias bbg=bbag
elif (( $+commands[ack] )); then
    alias bback='ack --type=bitbake'
    alias bbag=bback
    alias bbg=bbag
fi
alias bbfd="fd -t f -e bb -e inc -e conf -e bbclass -e bbappend"
alias bbfdf="bbfd ''"

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

