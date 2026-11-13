autoload -Uz add-zsh-hook

_command_failure_bell_preexec() {
    typeset -g _command_failure_bell_pending=1
}

_command_failure_bell_precmd() {
    local ret=$?
    if [[ ${_command_failure_bell_pending:-0} == 1 ]]; then
        _command_failure_bell_pending=0
        # Ctrl-C and early pager exits are intentional, not failures needing attention.
        if (( ret != 0 && ret != 130 && ret != 141 )); then
            printf '\a'
        fi
    fi
    return 0
}

add-zsh-hook preexec _command_failure_bell_preexec
add-zsh-hook precmd _command_failure_bell_precmd
