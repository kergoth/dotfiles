. ~/.sh/aliases
. ~/.sh/util
. ~/.sh/shopt
. ~/.sh/interactive
. ~/.sh/prompt

if [ -n "$BASH" -a -r /etc/bash_completion ]; then
    . /etc/bash_completion
fi
