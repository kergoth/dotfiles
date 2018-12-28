DIRCOLORS=$XDG_CONFIG_HOME/dir_colors
if (( $+commands[exa] )); then
    alias exa='exa --colour-scale'
    alias ls=exa
    alias la='ls -a'
    alias lr='ll -s modified'
elif [[ $OSTYPE =~ darwin ]] || [[ $OSTYPE =~ freebsd ]]; then
    if (( $+commands[gls] )); then
        alias ls='gls --color=auto -h'
        eval "$(gdircolors -b $DIRCOLORS)"
    else
        alias ls='ls -G -h'
    fi
    export LSCOLORS="$(cat $DOTFILESDIR/ls/bsd_colors)"
    alias la='ls -A'
    alias lr='ll -tr'
else
    if (( $+commands[dircolors] )); then
        eval "$(dircolors -b $DIRCOLORS)"
    fi
    alias ls='ls --color=auto -h'
    alias la='ls -A'
    alias lr='ll -tr'
fi

alias ll='ls -l'
alias l='ls -1'
