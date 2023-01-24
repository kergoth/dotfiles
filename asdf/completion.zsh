if [[ -e $ASDF_DATA_DIR/completions/asdf.bash ]]; then
    if autoload -Uz bashcompinit; then
        bashcompinit

        . $ASDF_DATA_DIR/completions/asdf.bash
    fi
fi
