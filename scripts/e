#!/bin/sh
VISUAL="${VISUAL:-${EDITOR:-vim}}"
case "$VISUAL" in
    codewait|code\ -w)
        # Synchronous editing via GUI, switch to async
        VISUAL=code
        ;;
esac
exec "$VISUAL" "$@"
