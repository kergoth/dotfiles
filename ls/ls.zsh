if [[ $OSTYPE =~ darwin ]]; then
    if (( $+commands[gls] )); then
        alias ls='gls --color=auto'
        eval "$(gdircolors -b $DOTFILESDIR/ls/dir_colors)"
    else
        alias ls='ls -G'
    fi
    export LSCOLORS="$(cat $DOTFILESDIR/ls/bsd_colors)"
else
    alias ls='ls --color=auto'
    eval "$(dircolors -b $DOTFILESDIR/ls/dir_colors)"
fi

alias lr='ls -thl'
alias ll='ls -hl'
alias la='ls -Ah'
alias l='ls -1h'
