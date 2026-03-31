if [[ $TERM_PROGRAM == "WarpTerminal" ]]; then
    PROMPT='%n@%m %1~ %# '
    RPROMPT=
    return
fi

if (( $+commands[starship] )); then
    : ${STARSHIP_CONFIG:=${XDG_CONFIG_HOME:-$HOME/.config}/starship-right.toml}
    export STARSHIP_CONFIG

    if eval "$(starship init zsh)"; then
        source "$ZDOTDIR/themes/transient-prompt/transient-prompt.zsh-theme"
        # Starship renders the active prompt and zsh-transient-prompt rewrites accepted prompts.
        TRANSIENT_PROMPT_PROMPT='$(starship prompt --terminal-width="$COLUMNS" --keymap="${KEYMAP:-}" --status="$STARSHIP_CMD_STATUS" --pipestatus="${STARSHIP_PIPE_STATUS[*]}" --cmd-duration="${STARSHIP_DURATION:-}" --jobs="$STARSHIP_JOBS_COUNT")'
        TRANSIENT_PROMPT_RPROMPT='$(starship prompt --right --terminal-width="$COLUMNS" --keymap="${KEYMAP:-}" --status="$STARSHIP_CMD_STATUS" --pipestatus="${STARSHIP_PIPE_STATUS[*]}" --cmd-duration="${STARSHIP_DURATION:-}" --jobs="$STARSHIP_JOBS_COUNT")'
        TRANSIENT_PROMPT_TRANSIENT_PROMPT='$(starship module character)'
        TRANSIENT_PROMPT_TRANSIENT_RPROMPT=''
        return
    fi
fi

PROMPT='%n@%m %1~ %# '
RPROMPT=
