if [[ $OSTYPE =~ darwin ]]; then
    if (( $+commands[gls] )); then
        alias ls='gls --color=auto'
        eval "$(gdircolors -b $DOTFILESDIR/ls/dir_colors)"
    else
        alias ls='ls -G'
    fi
else
    alias ls='ls --color=auto'
    eval "$(dircolors -b $DOTFILESDIR/ls/dir_colors)"
fi

if [[ -n "$LS_COLORS" ]]; then
    export LSCOLORS="$(gnu2bsd-lscolors)"
fi

alias lr='ls -thl'
alias ll='ls -hl'
alias la='ls -Ah'
alias l='ls -1h'
