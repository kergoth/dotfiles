DIRCOLORS=$XDG_CONFIG_HOME/dir_colors
if [[ $OSTYPE =~ darwin ]] || [[ $OSTYPE =~ freebsd ]]; then
    if (( $+commands[gdircolors] )); then
        eval "$(gdircolors -b $DIRCOLORS)"
    fi
fi
if (( $+commands[dircolors] )); then
    eval "$(dircolors -b $DIRCOLORS)"
fi

if (( $+commands[exa] )); then
    alias exa='exa --colour-scale'
    alias ls=exa
    alias la='ls -a'
    alias lr='ll -s modified'
    alias lrc='lr -s created'
elif [[ $OSTYPE =~ darwin ]] || [[ $OSTYPE =~ freebsd ]]; then
    if (( $+commands[gls] )); then
        alias ls='gls --color=auto -h'
    else
        alias ls='ls -G -h'
    fi
    export LSCOLORS="$(cat $DOTFILESDIR/ls/bsd_colors)"
    alias la='ls -A'
    alias lr='ll -tr'
    alias lrc='lr -U'
else
    alias ls='ls --color=auto -h'
    alias la='ls -A'
    alias lr='ll -tr'
    alias lrc='lr -c'
fi

alias ll='ls -l'
alias l='ls -1'
