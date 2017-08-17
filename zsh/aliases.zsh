alias reload!='. ${ZDOTDIR:-$HOME}/.zshrc'
alias import-global-history='fc -RI'

if [[ $OSTYPE =~ darwin ]]; then
    alias ls='ls -G'
else
    alias ls='ls --color=auto'
fi
alias lr='ls -thl'
alias ll='ls -hl'
alias la='ls -Ah'
alias l='ls -1h'

alias which=which-command
alias which-command='whence -avf'
alias tmux='tmux -u2 -f ~/.config/tmux/config'
alias bback='ack --type=bitbake'
alias chrome='google-chrome'
alias t.py='command t.py --task-dir ~/Dropbox/Documents'
alias t='t.py --list tasks.txt'
alias h='t.py --list tasks-personal.txt'
alias dtrx='dtrx --one=here'
alias mosh='mosh --forward-agent'
#alias mosh="perl -E 'print \'\e[?1005h\e[?1002h\''; mosh"
alias smem='smem -k'
alias ytdl=youtube-dl
alias youtube-dl='youtube-dl --write-sub --write-auto-sub --embed-subs --no-playlist -f best'
alias pipsi='pipsi --home="$WORKON_HOME"'
alias parallel='parallel --bibtex'
alias mr='mr -d "$(find_up .mrconfig || echo .)"'
alias sshnew='ssh -o "ControlPath none"'
alias diff='diff -urNd'

what () {
    tldr "$1" || cheat "$1" || man "$1"
}

pc () {
    pin-cushion "$1" --format json | jq .
}

pcless () {
    pin-cushion "$1" --format json | jq -C . | ${PAGER:-less}
}

# Convenience when pasting shell snippets
alias '$='

if (( $+commands[hub] )); then
    alias git=hub
fi
alias gitcolor='git -c color.ui=always'
alias gitnofancy='git -c "core.pager=diff-highlight | less --tabs=4 -RFX"'

if (( $+commands[pacman-color] )); then
    alias pacman='pacman-color'
fi

if (( $+commands[ack-grep] )); then
    alias ack='ack-grep --smart-case --pager=${PAGER:-less}'
else
    alias ack='ack --smart-case --pager=${PAGER:-less}'
fi

alias ag='ag -S --pager=${PAGER:-less}'

pt () {
    if [[ -t 1 ]]; then
        command pt -S --color --group "$@" | ${PAGER:-less}
    else
        command pt -S "$@"
    fi
}

if (( $+commands[pt] )); then
    alias bbag="pt -G '\.(bb|bbappend|inc|conf)$'"
    alias bbs=bbag
elif (( $+commands[ag] )); then
    alias bbag="ag -G '\.(bb|bbappend|inc|conf)$'"
    alias bbs=bbag
elif (( $+commands[ack] )); then
    alias ag=ack
    alias bback='ack --type=bitbake'
    alias bbag=bback
    alias bbs=bbag
fi

if (( $+commands[fzf] )); then
    _z_fzf () {
        if [[ $# -eq 0 ]]; then
            cd "$(_z -l 2>&1 | fzf +s --tac | sed 's/^[0-9,.]* *//')"
        else
            _z "$@"
        fi
    }
    alias z=_z_fzf
fi

if (( $+commands[vim] )); then
    alias vi=vim
fi

if [[ $OSTYPE =~ darwin ]]; then
    alias ps='ps ux'
    if (( $+commands[dfc] )); then
        alias df=dfc
        alias dfc='dfc -T'
    else
        alias df='df -P -h -T nodevfs,autofs,mtmfs'
    fi
    alias plaincopy='pbpaste -Prefer txt | pbcopy; pbpaste; echo'
    if (( $+commands[mvim] )); then
        alias vim='mvim -v'
    fi
    if (( $+commands[grm] )); then
        alias rm='grm --one-file-system -I'
    fi

    alias locate='mdfind -name'
    locate_app_by_id () {
        mdfind "kMDItemContentType == 'com.apple.application-bundle' && kMDItemCFBundleIdentifier == '$*'"
    }

    locate_app() {
        mdfind "kMDItemContentType == 'com.apple.application-bundle' && kMDItemDisplayName == '${*%.app}'cd"
    }

    alias daisydisk="open -b com.daisydiskapp.DaisyDiskStandAlone"
    alias ddisk=daisydisk
    alias marked="open -b com.brettterpstra.marked2"
else
    alias ps='ps fux'
    if (( $+commands[dfc] )); then
        alias df=dfc
        alias dfc='dfc -T -t -rootfs,tmpfs,devtmpfs,none'
    else
        alias df='df -h -x rootfs -x tmpfs -x devtmpfs -x none'
    fi
    alias rm='rm --one-file-system -I'
    alias open=xdg-open
fi
alias wildcard_to_re='python -c "import fnmatch,sys; print(fnmatch.translate(sys.argv[1]))"'
alias fnmatch='python -c "import fnmatch,sys; sys.exit(not fnmatch.fnmatch(*sys.argv[1:3]))"'
alias relpath='python -c "import os,sys; print(os.path.relpath(*sys.argv[1:]))"'
alias htmldecode='python -c "import HTMLParser,sys; print(HTMLParser.HTMLParser().unescape(sys.argv[1]))"'
alias common_prefix='python -c "import os,sys; print(os.path.commonprefix(sys.argv[1:]))"'
alias titlecase='python -c "import titlecase,sys; print(titlecase.titlecase(" ".join(sys.argv[1:])))"'
alias ddi=ddimage-sd
alias pg=pager

# zmv
autoload -U zmv
alias lln="noglob zmv -WL"
alias ccp="noglob zmv -WC"
alias mmv="noglob zmv -W"

# Suffixed for alias expansion
alias funced="_funced "

# Git
alias wgit='git clone --recursive'

# fls
fls () {
    if [ $# -eq 0 ]; then
        set -- *
    fi
    command fls -f %n%F "$@"
}
fll () {
    if [ $# -eq 0 ]; then
        set -- *
    fi
    command fls "$@"
}

# Startup time profiling
alias zsh-profile-startup="PROFILE_STARTUP=true zsh -i -c exit"
zsh-profile-startup-stats () {
    for i in $(seq 1 10); do zsh-profile-startup; done | sed 's,^[^ ]* ,,' | \
        sort -nrk2 | uniq -f 1 | stats --trim-outliers | less -RSXFE
}
alias vim-profile-startup="vim -c StartupTime"

# Global
alias -g G='| grep'
alias -g L='| less'
