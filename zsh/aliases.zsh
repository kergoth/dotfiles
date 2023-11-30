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
alias dtrx='dtrx --one=here'
alias mosh='mosh --forward-agent'
alias shfmt='shfmt -i 4 -ci -bn -s'
alias mr='mr -d "$(find_up .mrconfig || echo .)"'
alias sshnew='ssh -o "ControlPath none"'
alias diff='diff -urNd'
alias bc='bc -ql'
alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'
alias wfp=wait-for-process
alias ncdu='ncdu -e -x --color dark --exclude .git --exclude .repo'

if (( $+commands[direnv] )); then
    alias rezsh='exec direnv exec / zsh --login'
else
    alias rezsh='exec zsh --login'
fi

if [[ $OSTYPE =~ darwin ]]; then
    alias relogin='login -f $USER'
else
    alias relogin='su - $USER'
fi

alias atw=attach-workspace
alias wp=workspace-picker
alias wpa="workspace-picker -d -a"

unalias nw 2>/dev/null
nw () {
    update_env
    new-workspace "$@"
}


what () {
    tldr "$1" || cheat "$1" || man "$1" || eval '$1 --help' || eval '$1 -h'
}

# Convenience when pasting shell snippets
alias '$='

alias rgv=gv
alias rgva=gva
alias rg=g

if (( $+commands[podman] )) && ! (( $+commands[docker] )); then
    alias docker=podman
fi

if (( $+commands[fd] )); then
    if [[ $OSTYPE =~ darwin ]]; then
        fd () {
            if [[ -t 1 ]]; then
                command fd -i -c always "$@" | pager
            else
                command fd -i "$@"
            fi
        }
    else
        fd () {
            if [[ -t 1 ]]; then
                command fd -c always "$@" | pager
            else
                command fd "$@"
            fi
        }
    fi
else
    fd () {
        if (( $+commands[ag] )); then
            command ag -g "$@"
        else
            command ack -g "$@"
        fi
    }
fi

alias fdf="fd -t f ''"

if (( $+commands[prettyping] )); then
    ping () {
        if [[ -t 1 ]]; then
            prettyping --nolegend "$@"
        else
            command ping "$@"
        fi
    }
fi

if (( $+commands[unar] )); then
    # Use unar from the folks behind The Unarchiver if we have it
    extract() {
        for i; do
            unar "$i" || return $?
        done
    }
elif (( $+commands[aunpack] )); then
    # Or aunpack from atool
    alias extract='aunpack -e'
elif (( $+commands[unbox] )); then
    # Or unbox
    alias extract=unbox
else
    # Fall back to dtrx, which is included in the dotfiles
    extract () {
        dtrx --one=here --noninteractive "$@"
    }
fi

if (( $+commands[htop] )); then
    alias top=htop
fi

alias hardlink='hardlink -t -x "\\.git/" -x "\\.repo/" -x @ -x .DS_Store -x "\\.app/" -x "\\.sync/" -x "\\.itmf" -x "\\.ite" -x "\\.itc"'

if [[ $OSTYPE =~ darwin ]]; then
    alias ps='ps ux'
    alias plaincopy='pbpaste -Prefer txt | pbcopy; pbpaste; echo'

    alias locate='mdfind -name'
    alias ddisk=daisydisk
    alias marked="open -b com.brettterpstra.marked2"
else
    alias ps='ps fux'
    if ! (( $+aliases[open] )); then
        alias open=xdg-open
    fi
fi
alias duf='duf -hide-fs autofs,devfs,devtmpfs,tmpfs,mtmfs,none,squashfs,rootfs'
alias sbgrm='sudo =bgrm'

alias wildcard_to_re='python -c "import fnmatch,sys; print(fnmatch.translate(sys.argv[1]))"'
alias fnmatch='python -c "import fnmatch,sys; sys.exit(not fnmatch.fnmatch(*sys.argv[1:3]))"'
alias relpath='python -c "import os,sys; print(os.path.relpath(*sys.argv[1:]))"'
alias htmldecode='python -c "import HTMLParser,sys; print(HTMLParser.HTMLParser().unescape(sys.argv[1]))"'
alias common_prefix='python -c "import os,sys; print(os.path.commonprefix(sys.argv[1:]))"'
alias ddi=ddimage-sd
alias pg=pager

# zmv
autoload -U zmv
alias lln="noglob zmv -WL"
alias ccp="noglob zmv -WC"
alias mmv="noglob zmv -W"

# Suffixed for alias expansion
alias funced="_funced "

# Startup time profiling
alias zsh-profile-startup="PROFILE_STARTUP=true zsh -i -c exit"
alias zsh-profile-startup-lines="PROFILE_STARTUP_LINES=true zsh -i -c exit"
zsh-profile-startup-stats () {
    for i in $(seq 1 10); do zsh-profile-startup-lines; done | sed 's,^[^ ]* ,,' | \
        sort -nrk2 | uniq -f 1 | stats --trim-outliers | less -RSXFE
}

# Global
alias -g G='| grep'
alias -g L='| less'
alias -g X='| nlxargs'
alias -g W='| while read -r '
