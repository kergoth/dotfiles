#!/bin/sh

case "$1" in
    *.md|*.markdown)
        if which mdless >/dev/null 2>&1; then
            exec mdless --no-pager "$1"
        fi
        ;;
    *.diff|*.patch)
        if which diff-so-fancy >/dev/null 2>&1; then
            lesspipe.sh "$1" | diff-so-fancy
            exit $?
        elif which diff-highlight >/dev/null 2>&1; then
            lesspipe.sh "$1" | diff-highlight
            exit $?
        fi
        ;;
esac
exec lesspipe.sh "$1"
