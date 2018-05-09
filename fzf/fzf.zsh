. $DOTFILESDIR/fzf/themes/base16-tomorrow-night.config

if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd -c always -t f ""'
    export FZF_ALT_C_COMMAND='fd -c always -t d ""'
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --ansi"
else
    export FZF_DEFAULT_COMMAND='ag --color -g ""'
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
