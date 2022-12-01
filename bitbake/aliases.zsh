# Run in docker when appropriate
for cmd in devtool recipetool bitbake bitbake-layers \
            bitbake-diffsigs bitbake-dumpsig bitbake-getvar \
            bitbake-getvars bitbake-selftest; do
    alias $cmd="oe-docker-exec $cmd"
done

if (( $+commands[rg] )); then
    alias bbrg="command rg -t bitbake"
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

