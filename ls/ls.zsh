if [[ -e "$DOTFILESDIR/ls/ls_colors" ]]; then
    export LS_COLORS="$(<"$DOTFILESDIR/ls/ls_colors")"
else
    if [[ -e "$DOTFILESDIR/ls/dir_colors" ]]; then
        DIRCOLORS=$XDG_CONFIG_HOME/dir_colors
    fi

    if [[ $OSTYPE =~ darwin ]] || [[ $OSTYPE =~ freebsd ]]; then
        if (( $+commands[gdircolors] )); then
            eval "$(gdircolors -b ${=DIRCOLORS:+-b "$DIRCOLORS"})"
        fi
    fi
    if (( $+commands[dircolors] )); then
        eval "$(dircolors -b ${=DIRCOLORS:+-b "$DIRCOLORS"})"
    fi
fi

if (( $+commands[eza] )); then
    alias eza='eza --colour-scale all'
    alias ls=eza
    alias la='ls -a'
    alias lr='ll -s modified'
    alias lrc='lr -s created'
elif (( $+commands[exa] )); then
    alias exa='exa --colour-scale all'
    alias ls=exa
    alias la='ls -a'
    alias lr='ll -s modified'
    alias lrc='lr -s created'
elif [[ $OSTYPE =~ darwin ]] || [[ $OSTYPE =~ freebsd ]]; then
    if (( $+commands[gls] )); then
        alias ls='gls --color=auto -h'
    else
        alias ls='ls -G -h'
        if [[ -e "$DOTFILESDIR/ls/bsd_colors" ]]; then
            export LSCOLORS="$(cat $DOTFILESDIR/ls/bsd_colors)"
        fi
    fi
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
