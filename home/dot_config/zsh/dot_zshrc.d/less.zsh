# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS='-F -g -i -M -R -w -X -z-4'

if (( $+commands[less] )); then
    export PAGER=less

    if ! (( $+commands[bat] )); then
        man() {
            env \
                LESS_TERMCAP_mb=$'\e[1;31m' \
                LESS_TERMCAP_md=$'\e[1;34m' \
                LESS_TERMCAP_so=$'\e[01;45;37m' \
                LESS_TERMCAP_us=$'\e[01;36m' \
                LESS_TERMCAP_me=$'\e[0m' \
                LESS_TERMCAP_se=$'\e[0m' \
                LESS_TERMCAP_ue=$'\e[0m' \
                GROFF_NO_SGR=1 \
                man "$@"
        }
    fi
fi
