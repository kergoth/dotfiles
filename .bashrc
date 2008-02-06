. ~/.sh/aliases
. ~/.sh/util
. ~/.sh/shopt
. ~/.sh/interactive

if [ -n "$BASH" ]; then
    if [ -e /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
    for c in ~/.sh/complete.d/*; do
        if [ -e $c ]; then
            . $c
        fi
    done
fi
