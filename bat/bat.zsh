if (( $+commands[bat] )); then
    LESSCOLORIZER="${LESSCOLORIZER:-bat --decorations never}"
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"
fi
