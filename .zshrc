# Prompt theming
# autoload -U promptinit
# promptinit

# Enable parameter substition in prompts
setopt prompt_subst

# PROMPT='[%D{%L:%M}] %15<…<%~ %% '
# PROMPT='[%D{%L:%M}] %10<...<%~ %%'
# PROMPT='[%D{%L:%M}]%1~%% '
PROMPT='%(2L.+.)$PROMPTCONTEXT%n@%m %1~%# '

typeset -a _PROMPTCONTEXT
if [[ -n $VIM ]]; then
    _PROMPTCONTEXT+="vim"
fi
if [[ -n $CLEARCASE_ROOT ]]; then
    _PROMPTCONTEXT+=${${(s,/,)CLEARCASE_ROOT}[3]}
fi
if [[ -n $debian_chroot ]]; then
    _PROMPTCONTEXT+=$debian_chroot
elif [[ -r /etc/debian_chroot ]]; then
    _PROMPTCONTEXT+=$(</etc/debian_chroot)
fi
if [[ ${#_PROMPTCONTEXT} -gt 0 ]]; then
    PROMPTCONTEXT="[${(j,][,)_PROMPTCONTEXT}] "
else
    PROMPTCONTEXT=""
fi
unset _PROMPTCONTEXT

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

function diff() {
    typeset diffcmd="$(where colordiff)"
    command ${diffcmd:-diff} -uNd "$@" | $PAGER -p '^diff '
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
    if type -p tput &>/dev/null; then
        numcolors=$(tput colors)
    else
        numcolors=2
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

# Set xterm window title to user@host:pwd
chpwd() {
    typeset title="%n@%m:%~"
    [[ -t 1 ]] || return
    case $TERM in
    (sun-cmd) print -Pn "\e]l$title\e\\"
        ;;
    (*xterm*|rxvt*|(dt|k|E)term) print -Pn "\e]2;$title\a"
        ;;
    esac
}
chpwd

namedir code ~/code
namedir linus ~/code/kernel-upstream/linux
namedir cge40 /media/nfshome/cge_40
namedir cge50 /media/nfshome/cge_50
namedir pro40 /media/nfshome/pro_40
namedir pro50 /media/nfshome/pro_50
namedir other ~/code/other
namedir upstream ~/code/other-upstream
namedir snippets ~/code/snippets

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
