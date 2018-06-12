alias import-global-history='fc -RI'

- () {
    if [[ -o auto_pushd ]]; then
        popd
    else
        cd -
    fi
}

alias which=which-command
alias which-command='whence -avf'
alias gdb='gdb -nh -x "$XDG_CONFIG_HOME"/gdb/init'
alias grep='grep --color=auto'
alias tmux='tmux -u2 -f ~/.config/tmux/config'
alias chrome='google-chrome'
alias t.py='command t.py --task-dir ~/Dropbox/Documents'
alias t='t.py --list tasks.txt'
alias h='t.py --list tasks-personal.txt'
alias dtrx='dtrx --one=here'
alias mosh='mosh --forward-agent'
#alias mosh="perl -E 'print \'\e[?1005h\e[?1002h\''; mosh"
alias smem='smem -k'
alias parallel='parallel --bibtex'
alias shfmt='shfmt -i 4 -ci -bn -s'
alias mr='mr -d "$(find_up .mrconfig || echo .)"'
alias sshnew='ssh -o "ControlPath none"'
alias diff='diff -urNd'
alias bc='bc -ql'
alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'
alias xz='xz --threads=0'
alias rezsh='exec zsh --login'
if [[ $OSTYPE =~ darwin ]]; then
    alias relogin='exec login -f $USER'
else
    alias relogin='exec su - $USER'
fi

what () {
    tldr "$1" || cheat "$1" || man "$1" || eval '$1 --help' || eval '$1 -h'
}

# Convenience when pasting shell snippets
alias '$='

if (( $+commands[ack-grep] )); then
    alias ack='ack-grep --smart-case --pager=${PAGER:-less}'
else
    alias ack='ack --smart-case --pager=${PAGER:-less}'
fi

alias ag='ag -S --pager=${PAGER:-less} --color-path "1;34" --color-line-number "1;33" --color-match "30;43"'

pt () {
    if [[ -t 1 ]]; then
        command pt -S --color --group "$@" | ${PAGER:-less}
    else
        command pt -S "$@"
    fi
}

if ! (( $+commands[ag] )) && (( $+commands[ack] )); then
    alias ag=ack
fi

fd () {
    if [[ -t 1 ]]; then
        command fd -c always "$@" | pager
    else
        command fd "$@"
    fi
}

alias fdf="fd -t f ''"

if [[ $OSTYPE =~ darwin ]]; then
    alias ps='ps ux'
    if (( $+commands[dfc] )); then
        alias df=dfc
        alias dfc='dfc -T'
    else
        alias df='df -P -h -T nodevfs,autofs,mtmfs'
    fi
    alias plaincopy='pbpaste -Prefer txt | pbcopy; pbpaste; echo'
    if (( $+commands[grm] )); then
        alias rm='grm --one-file-system -I'
    fi

    alias locate='mdfind -name'
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

# Startup time profiling
alias zsh-profile-startup="PROFILE_STARTUP=true zsh -i -c exit"
zsh-profile-startup-stats () {
    for i in $(seq 1 10); do zsh-profile-startup; done | sed 's,^[^ ]* ,,' | \
        sort -nrk2 | uniq -f 1 | stats --trim-outliers | less -RSXFE
}

# Global
alias -g G='| grep'
alias -g L='| less'
