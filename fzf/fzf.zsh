if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd -t f ""'
else
    export FZF_DEFAULT_COMMAND='ag -g ""'
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

. $DOTFILESDIR/fzf/themes/base16-tomorrow-night.config
