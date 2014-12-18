alias reload!='. ${ZDOTDIR:-$HOME}/.zshrc'

if [[ $OSTYPE =~ darwin ]]; then
    alias ls="ls -G"
else
    alias ls="ls --color=auto"
fi
alias lr="ls -thl"
alias ll="ls -hl"
alias la="ls -Ah"
alias l="ls -1h"

alias tmux='tmux -u2 -f ~/.config/tmux/config'
alias bback='ack --type=bitbake'
alias chrome='google-chrome'
alias t.py='command t.py --task-dir ~/Dropbox/Documents'
alias t='t.py --list tasks.txt'
alias h='t.py --list tasks-personal.txt'
alias dtrx='dtrx --one=here'
alias mosh='mosh --forward-agent'
#alias mosh="perl -E 'print \"\e[?1005h\e[?1002h\"'; mosh"
alias smem='smem -k'
alias ytdl=youtube-dl
alias pipsi='pipsi --home="$WORKON_HOME"'

if (( $+commands[hub] )); then
    eval $(hub alias -s zsh)
fi

if (( $+commands[pacman-color] )); then
    alias pacman='pacman-color'
fi

alias ag="ag -S --pager=${PAGER:-less}"
if (( $+commands[ag] )); then
    alias bbag="ag -G '\.(bb|bbappend|inc|conf)$'"
elif (( $+commands[ack] )); then
    alias ag=ack
    alias bback='ack --type=bitbake'
    alias bbag=bback
fi

if [[ $OSTYPE =~ darwin ]]; then
    alias ps="ps ux"
    if (( $+commands[dfc] )); then
        alias df=dfc
        alias dfc="dfc -T"
    fi
    alias cpanm="cpanm --local-lib ~/Library/Perl/*"
    alias locate="mdfind -name"
    alias vim="mvim -v"
else
    alias ps="ps fux"
    if (( $+commands[dfc] )); then
        alias df=dfc
        alias dfc="dfc -T -q mount -p -rootfs"
    fi
    alias rm="rm --one-file-system"
fi

# Global
alias -g G="| grep"
alias -g L="| less"
