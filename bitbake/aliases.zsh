get-bbvar () {
    local var="$1"
    shift
    if [ $# -gt 0 ]; then
        local recipe="$1"
        shift
        set -- -r "$recipe" "$@"
    fi
    bitbake-getvar --value "$@" "$var" | grep -Ev '^(useradd|NOTE|ERROR|WARNING): '
}

cd-workdir () {
    cd "$(get-bbvar WORKDIR "$1" | tr -d '\r\n')"
}

cd-srcdir () {
    cd "$(get-bbvar S "$1" | tr -d '\r\n')"
}

cd-objdir () {
    cd "$(get-bbvar B "$1" | tr -d '\r\n')"
}

bbrebuild () {
    bitbake -c clean "$@" && bitbake -C configure -k "$@"
}

bbrebake () {
    bitbake -c clean "$@" && bitbake -k "$@"
}

alias bblayers=bitbake-layers

alias bb="oe-docker-run bb"
alias bitbake-diffsigs="oe-docker-run bitbake-diffsigs"
alias bitbake-dumpsig="oe-docker-run bitbake-dumpsig"
alias bitbake-getvar="oe-docker-run bitbake-getvar"
alias bitbake-getvars="oe-docker-run bitbake-getvars"
alias bitbake-layers="oe-docker-run bitbake-layers"
alias bitbake="oe-docker-run bitbake"
alias devtool="oe-docker-run devtool"
alias recipetool="oe-docker-run recipetool"
