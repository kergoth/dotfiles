# Don't show a failure exit code in the prompt when no command was run,
# for example when I ^C at the prompt

. $ZSH/promptline.zsh

promptline_lastcmd=

promptline_begin() {
    promptline_lastcmd=$1
}
add-zsh-hook preexec promptline_begin

promptline_last_code_fixup() {
    if [[ -z "$promptline_lastcmd" ]]; then
        PROMPTLINE_LAST_EXIT_CODE=0
    else
        PROMPTLINE_LAST_EXIT_CODE=
    fi
    promptline_lastcmd=
}

if [[ ! ${precmd_functions[(r)promptline_last_code_fixup]} == promptline_last_code_fixup ]]; then
    precmd_functions=(promptline_last_code_fixup $precmd_functions)
fi

if [[ $OSTYPE = WSL ]] && [[ $WSL_IS_ADMIN = 1 ]]; then
    add_wsl_admin() {
        RPROMPT="$RPROMPT [wsladmin]"
    }
    add-zsh-hook precmd add_wsl_admin
fi
