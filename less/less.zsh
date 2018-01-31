# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS='-F -g -i -M -R -w -X -z-4'

export LESSOPEN="|mylesspipe.sh %s"
if (( $+commands[pygmentize] )); then
    # If we have pygmentize, prefer it over code2color
    export LESSCOLORIZER=mypygmentize
    export PYGMENTIZE_FORMATTER=terminal
    # TODO: cache this, to avoid zsh load time increase
    if pygmentize -S base16-tomorrow-night -f $PYGMENTIZE_FORMATTER >/dev/null; then
        export PYGMENTIZE_STYLE=base16-tomorrow-night
    else
        export PYGMENTIZE_STYLE=monokai
    fi
fi
