if (( $+commands[bat] )); then
    BAT_THEME=base16-tomorrow-night
    alias bat="bat ${BAT_THEME+--theme=$BAT_THEME}"
    LESSCOLORIZER="${LESSCOLORIZER:-bat --decorations never}"
fi
