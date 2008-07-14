# TODO:
# - Copy zshrc bits from folks.
# - Add completion for 'daemon', minimally, complete non-options as commands
#   from the path.
# - I'm currently calling out less on every ls call, to be more like git,
#   automatically using a pager if needed.  Unfortunately, there are a couple
#   terminal behavior consequences when the amount of data is less than one
#   page.  It exits when there's less than one page, which is good, however it
#   prints at the bottom of the terminal even if there was room at the top,
#   and it prints a blank line after the output, which bugs me.  See what can
#   be done about this.  Worst case, we could redirect the ls output, check
#   the length, and send the temporary file through to the pager.
# - Get in the habit of using lowercase variable names for arrays and
#   uppercase for scalars, just for consistency.

# Prompt theming
# autoload -U promptinit
# promptinit

# Enable parameter substition in prompts
setopt prompt_subst

# PROMPT='[%D{%L:%M}] %15<…<%~ %% '
# PROMPT='[%D{%L:%M}] %10<...<%~ %%'
# PROMPT='[%D{%L:%M}]%1~%% '
PROMPT='%(2L.+.)$PROMPTCONTEXT%n@%m %1~%# '

typeset -a context
if [[ -n $VIM ]]; then
    context+="vim"
fi
if [[ -n $CLEARCASE_ROOT ]]; then
    context+=${${(s,/,)CLEARCASE_ROOT}[3]}
fi
if [[ -n $debian_chroot ]]; then
    context+=$debian_chroot
elif [[ -r /etc/debian_chroot ]]; then
    context+=$(</etc/debian_chroot)
fi
if [[ ${#context} -gt 0 ]]; then
    PROMPTCONTEXT="[${(j,][,)context}] "
else
    PROMPTCONTEXT=""
fi
unset context

# Freeze the terminal's settings, so nothing can corrupt it
ttyctl -f

# History
HISTFILE=~/.zsh/history
SAVEHIST=1000
HISTSIZE=1000
setopt hist_reduce_blanks
setopt inc_append_history

# Disable the annoying beeps
setopt no_beep

# Only allow items in these variables which aren't already there
typeset -U PATH path FPATH fpath MANPATH manpath CDPATH cdpath

# Pair up LD_LIBRARY_PATH with an ldlibpath array
export -TU LD_LIBRARY_PATH ldlibpath

# Local paths
fpath=(~/.zsh/functions $fpath)
path=(~/bin ~/.root/bin $path)
manpath=(~/.root/man ~/.root/share/man $manpath /usr/local/share/man /usr/local/man /usr/share/man /usr/man)
ldlibpath=(~/.root/lib $ldlibpath)

# Autoload my functions
# autoload -U ${fpath[1]}/*(:t)

# Autoload all shell functions from all directories in $fpath (following
# symlinks) that have the executable bit on (the executable bit is not
# necessary, but gives you an easy way to stop the autoloading of a
# particular shell function). $fpath should not be empty for this to work.
for func in $^fpath/*(N-.x:t); autoload $func

# Disable clobbering
setopt no_clobber

# Aliases
alias j=jobs
alias d=dirs
alias pu=pushd
alias po=popd
alias ct='cleartool'
alias cpe='clearprojexp'
alias hd='od -t x1'
alias mt='monotone'
alias bb='bitbake'
alias rem='remind'
alias se=sudoedit
alias more=less
alias rgrep='grep -nrI'
alias grep='grep -n'
alias gvim='vim -g'
alias vi=vim

function diff() {
    typeset diffcmd="diff"
    if have colordiff; then
        diffcmd=colordiff
    fi
    command $diffcmd -uNd "$@" | $PAGER -p '^diff '
}

function difftree() {
        if [ $# -ne 2 ]; then
                echo "usage: dt <dirname1> <dirname2>"
                echo "diff two directories recursively"
        else
            command diff -urNd -X ~/.sh/dontdiff "$@" | $PAGER -p '^diff '
        fi
}
alias dt=difftree

function svndiff() {
        svn diff "$@" | colordiff | $PAGER -p '^Index.*'
}
alias svnd=svndiff

if [[ -t 1 ]]; then
    typeset +r -i numcolors
    if have tput; then
        numcolors=$(tput colors)
    else
        case $TERM in
            (cygwin)
                numcolors=8
                ;;
            (putty-256color)
                numcolors=256
                ;;
            (*)
                numcolors=2
                ;;
        esac
    fi
    typeset -r numcolors
fi

if [[ $numcolors -gt 2 ]]; then
    if [[ -f ~/.dir_colors ]]; then
        eval `dircolors -b ~/.dir_colors`
    else
        eval `dircolors`
    fi
fi

ls () {
    typeset colorarg
    if [[ $numcolors -gt 2 ]]; then
        colorarg="--color=always"
    else
        colorarg="-F"
    fi
    command ls -CApBhq $colorarg "$@" | $PAGER
}

# List only directories and symbolic
# links that point to directories
alias lsd='ls -ld *(-/DN)'
# List only file beginning with "."
alias lsa='ls -ld .*'
# List with recent files first
alias lsr='ls -t'
alias lr='ls -lt'

# Color git grep
alias gg='GREP_OPTIONS=--color=always git-grep'

# alias ps='ps -o user,group,pid,sess,stat,wchan:8,cmd --forest'
alias ps='ps -o user,group,pid,stat,cmd --forest'

# Break old habits
ps() {
    if [[ $4 = "-ef" || $4 = "aux" ]]; then
        echo >&2 "ps: error: given our aliases, you don't want to use those arguments."
        echo >&2 "ps: perhaps you meant 'ps -e' or 'psgrep' or 'ppsgrep'?"
        return 1
    fi
    command ps "$@"
}

e () {
    $EDITOR "$@"
}

function wrap_restoretitle () {
    for app in $argv; do
        eval "function $app () {
            setopt localtraps
            trap chpwd EXIT
            trap chpwd INT
            command $app \"\$@\"
        }"
    done
}
wrap_restoretitle vim ssh screen

function wrap_settitle () {
    for app in $argv; do
        eval "function $app () {
            setopt localtraps

            typeset oldtitle=\$overridetitle
            case \$TERM in
            (screen*)
                title $app
                ;;
            (*)
                title $app "\$@"
                ;;
            esac

            trap chpwd EXIT
            trap chpwd INT
            command $app \"\$@\"
            overridetitle=\$oldtitle
        }"
    done
}
wrap_settitle make ./configure tmake qmake scons cmake

alias termtitle=title
title () {
    overridetitle="$*"
    [[ -t 1 ]] || return
    case $TERM in
    (sun-cmd)
        print -Pn "\e]l$*\e\\"
        ;;
    (xterm*|rxvt*|(dt|k|E)term|putty*)
        print -Pn "\e]2;$*\a"
        ;;
    (screen*)
        print -Pn "\ek$*\e\\"
        ;;
    (*)
        overridetitle=
        ;;
    esac
}

resettermtitle () {
    overridetitle=
}

# Set xterm window title to user@host:pwd
chpwd() {
    if [[ -n $overridetitle ]]; then
        termtitle $overridetitle
    else
        typeset title
        case $TERM in
        (screen*)
            title="%m:%~"
            ;;
        (*)
            title="%n@%m:%~"
            ;;
        esac
        termtitle $title
        overridetitle=
    fi
}
chpwd

namedir code ~/code
namedir other ~/code/other
namedir snippets ~/code/snippets

case $HOST in
    (foul)
        namedir linus ~/code/kernel-upstream/linux
        namedir upstream ~/code/other-upstream
        namedir cge40 /media/nfshome/cge_40
        namedir cge50 /media/nfshome/cge_50
        namedir pro40 /media/nfshome/pro_40
        namedir pro50 /media/nfshome/pro_50
        ;;
    (scratch-1)
        namedir cge40 ~/cge_40
        namedir cge50 ~/cge_50
        namedir pro40 ~/pro_40
        namedir pro50 ~/pro_50
        ;;
esac

zstyle :compinstall filename ~/.zshrc
autoload -Uz compinit
compinit

typeset -a users
cat /etc/passwd|cut -d: -f1-3|sed -e's,:, ,g'|while read username password uid; do
    if [[ $uid -gt 999 ]]; then
        users+=$username
    fi
done

zstyle ':completion:*' users $users

# color!
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# case insensitivity for the win
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# offer indexes before parameters in subscripts
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# complete all user processes
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:*:processes-names' command 'ps -au$USER -o command'

# perty kill process display
zstyle ':completion:*:*:kill:*:processes' command 'ps -au$USER --forest -o pid,user,cmd'

typeset -a hosts
hosts=(hyperion.kergoth.com covenant.kergoth.com neutrino.file-radio.com)

typeset -A aliasedhosts
aliasedhosts[faldain]=192.168.1.100
aliasedhosts[hawkins]=192.168.1.124
aliasedhosts[anarch]=192.168.1.1
for host in ${(k)aliasedhosts}; do
    alias -g $host=${aliasedhosts[$host]}
done

local _etc_hosts _known_hosts _ssh_hosts
_etc_hosts=( ${${${(f)"$(</etc/hosts)"}/\#*}#*[\t ]} )
_known_hosts=( ${${(f)"$(<~/.ssh/known_hosts)"}//[ ,#]*/} )
_ssh_hosts=( ${${${(f)"$(egrep -i '^host ' ~/.ssh/config)"}//* /}%%*\**} )
zstyle ':completion:*' hosts $_etc_hosts $_known_hosts $_ssh_hosts ${(v)aliasedhosts} $hosts
zstyle ':completion:*:(ssh|scp|sftp):*' hosts $_etc_hosts $_known_hosts $_ssh_hosts ${(v)aliasedhosts} $hosts
unset _etc_hosts _known_hosts _ssh_hosts aliasedhosts hosts
