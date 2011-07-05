. ~/.sh/volatile
. ~/.sh/util
. ~/.sh/aliases
. ~/.sh/shopt
. ~/.sh/interactive
. ~/.sh/prompt

if [ -n "$BASH" ]; then
    if [ -r /etc/bash_completion ]; then
        . /etc/bash_completion
    elif [ -r /etc/bash_completion.d ]; then
        for c in /etc/bash_completion.d/*; do
            if [ -r $c ]; then
                . $c
            fi
        done
        . ~/.bash_completion
    fi
fi
