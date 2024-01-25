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
alias chrome='google-chrome'
alias t.py='command t.py --task-dir ~/Dropbox/Documents'
alias t='t.py --list tasks.txt'
alias h='t.py --list tasks-personal.txt'
alias dtrx='dtrx --one=here'
alias mosh='mosh --forward-agent'
alias smem='smem -k'
alias shfmt='shfmt -i 4 -ci -bn -s'
alias mr='mr -d "$(find_up .mrconfig || echo .)"'
alias sshnew='ssh -o "ControlPath none"'
alias diff='diff -urNd'
alias bc='bc -ql'
alias wget='wget --hsts-file="$XDG_CACHE_HOME/wget-hsts"'
alias wfp=wait-for-process
alias ncdu='ncdu -e -x --color dark --exclude .git --exclude .repo'
if (( $+commands[direnv] )); then
    alias tmux='direnv exec / tmux -u2 -f ~/.config/tmux/config'
else
    alias tmux='tmux -u2 -f ~/.config/tmux/config'
fi
alias nixgc="nix-collect-garbage -d"
alias nixq="nix-env --description -qaP"
alias gitcolor='git -c color.ui=always'
alias gitnofancy='git -c "core.pager=diff-highlight | less --tabs=4 -RFX"'
alias gitnopager='git -c "core.pager=cat"'

alias gcl='git clone --recursive'
alias gncl='git clone'

alias ghcl='gh repo clone'
alias gist='gh gist create'

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
alias duf='duf -hide-fs autofs,devfs,devtmpfs,tmpfs,mtmfs,none,squashfs,rootfs,overlay,fuse.snapfuse -hide-mp /snap'
alias sbgrm='sudo =bgrm'

alias wildcard_to_re='python -c "import fnmatch,sys; print(fnmatch.translate(sys.argv[1]))"'
alias fnmatch='python -c "import fnmatch,sys; sys.exit(not fnmatch.fnmatch(*sys.argv[1:3]))"'
alias relpath='python -c "import os,sys; print(os.path.relpath(*sys.argv[1:]))"'
alias htmldecode='python -c "import HTMLParser,sys; print(HTMLParser.HTMLParser().unescape(sys.argv[1]))"'
alias common_prefix='python -c "import os,sys; print(os.path.commonprefix(sys.argv[1:]))"'
alias ddi=ddimage-sd
alias pg=pager

# bitbake
if (( $+commands[rg] )); then
    alias bbrg="command rg -t bitbake"
    alias bbg=bbrg
elif (( $+commands[pt] )); then
    alias bbag="pt -G '\.(bb|bbappend|inc|conf)$'"
    alias bbg=bbag
elif (( $+commands[ag] )); then
    alias bbag="ag -G '\.(bb|bbappend|inc|conf)$'"
    alias bbg=bbag
elif (( $+commands[ack] )); then
    alias bback='ack --type=bitbake'
    alias bbag=bback
    alias bbg=bbag
fi
alias bbfd="fd -t f -e bb -e inc -e conf -e bbclass -e bbappend"
alias bbfdf="bbfd ''"

# zmv
autoload -U zmv
alias lln="noglob zmv -WL"
alias ccp="noglob zmv -WC"
alias mmv="noglob zmv -W"

# Suffixed for alias expansion
alias funced="_funced "

# Startup time profiling
alias zsh-profile-startup="ZSH_PROFILE_STARTUP=true zsh -i -c exit"
alias zsh-profile-startup-lines="ZSH_PROFILE_STARTUP_LINES=true zsh -i -c exit"
zsh-profile-startup-stats () {
    for i in $(seq 1 10); do zsh-profile-startup-lines; done | sed 's,^[^ ]* ,,' | \
        sort -nrk2 | uniq -f 1 | stats --trim-outliers | less -RSXFE
}

# Git
alias gitcolor='git -c color.ui=always'
alias gitnofancy='git -c "core.pager=diff-highlight | less --tabs=4 -RFX"'
alias gitnopager='git -c "core.pager=cat"'

alias gcl='git clone --recursive'
alias gncl='git clone'

alias ghcl='gh repo clone'
alias gist='gh gist create'

# WSL
if [[ $OSTYPE = WSL ]]; then
    winver () {
        ( cd "$USERPROFILE" && cmd.exe /c ver )
    }

    if ! (( $+commands[xdg-open] )); then
        alias open=wsl-open
    fi

    alias cdw='cd "$USERPROFILE"'
    alias start="cmd.exe /c start"
    alias cmd=cmd.exe
    alias wsl=wsl.exe
    alias adminwsl="psadmin wsl.exe"
    alias wt=wt.exe
    alias adminwt="psadmin 'shell:appsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App'"
    alias adb=adb.exe

    alias trash=recycle
    alias scoop="noglob scoop"

    if [[ -z "$WSL_IS_ADMIN" ]]; then
        if net.exe session >/dev/null 2>&1; then
            export WSL_IS_ADMIN=1
        else
            export WSL_IS_ADMIN=0
        fi
    fi
fi

# Global
alias -g G='| grep'
alias -g L='| less'
alias -g X='| nlxargs'
alias -g W='| while read -r '
