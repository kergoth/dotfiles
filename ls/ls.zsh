DIRCOLORS=$XDG_CONFIG_HOME/dir_colors
if [[ $OSTYPE =~ darwin ]]; then
    if (( $+commands[gls] )); then
        alias ls='gls --color=auto'
        eval "$(gdircolors -b $DIRCOLORS)"
    else
        alias ls='ls -G'
    fi
    export LSCOLORS="$(cat $DOTFILESDIR/ls/bsd_colors)"
else
    alias ls='ls --color=auto'
    eval "$(dircolors -b $DIRCOLORS)"
fi

alias lr='ls -thl'
alias ll='ls -hl'
alias la='ls -Ah'
alias l='ls -1h'
