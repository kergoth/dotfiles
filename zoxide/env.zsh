if (( $+commands[zoxide] )); then
    export _ZO_DATA_DIR=$XDG_DATA_HOME/zoxide
    export _ZO_FZF_OPTS=$FZF_DEFAULT_OPTS
fi
