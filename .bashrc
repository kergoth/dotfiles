. ~/.sh/aliases
. ~/.sh/util
. ~/.sh/shopt
. ~/.sh/interactive

if [ -n "$BASH" ]; then
    for c in ~/.sh/complete.d/*; do
        if [ -e $c ]; then
            . $c
        fi
    done
fi
