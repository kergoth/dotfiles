#!/bin/sh

case "$1" in
    *.md|*.markdown)
        if which mdless >/dev/null 2>&1; then
            exec mdless "$1"
        fi
        ;;
esac
exec lesspipe.sh "$1"
