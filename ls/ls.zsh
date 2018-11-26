DIRCOLORS=$XDG_CONFIG_HOME/dir_colors
if (( $+commands[exa] )); then
    alias exa='exa --colour-scale'
    alias ls=exa
    alias la='exa -a'
    alias lr='exa -l -s modified'
elif [[ $OSTYPE =~ darwin ]]; then
    if (( $+commands[gls] )); then
        alias ls='gls --color=auto -h'
        eval "$(gdircolors -b $DIRCOLORS)"
    else
        alias ls='ls -G -h'
    fi
    export LSCOLORS="$(cat $DOTFILESDIR/ls/bsd_colors)"
    alias la='ls -A'
    alias lr='ls -lt'
else
    eval "$(dircolors -b $DIRCOLORS)"
    alias ls='ls --color=auto -h'
    alias la='ls -A'
    alias lr='ls -lt'
fi

alias ll='ls -l'
alias l='ls -1'
