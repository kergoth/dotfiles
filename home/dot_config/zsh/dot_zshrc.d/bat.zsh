if (( $+commands[bat] )); then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"

    bathelp() {
        bat --plain --language=help "$@"
    }
    help() {
        "$@" --help 2>&1 | bathelp
    }
fi
