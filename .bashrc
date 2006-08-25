ipkgfiles () {
    ar p $1 data.tar.gz | tar -tvz
    return $?
}

ipkgcontrol () {
    ar p $1 control.tar.gz | tar -zxO ./control
    return $?
}

bkdiffs () {
    if [ "$1" = "--help" ]; then
        cat <<END >&2
bkdiffs is shell function for running diffs of local
modifications against a bitkeeper repository.

Usage: bkdiffs [paths...]

Examples:

To see all the local modifications in the repo:
bkdiffs -u

To see all the local modifications in that dir:
bkdiffs -u uclibc

To see all the local modifications to Makefile:
bkdiffs -u Makefile
END
        return 2
    fi
    files=$*
    if [ -n "$files" ]; then
        for f in $files; do
            if [ -d $f ]; then
                (cd $f; bkdiffs -u)
            else
                bk diffs -u $f
            fi
        done
    else
        bk sfiles -Uc | bk diffs -u -
    fi
}

bkpending () {
    bk sfiles -U -pC
}

bkmodified () {
    bk sfiles -Uc
}

bkeditall () {
    bk sfiles -U | bk edit -
}

termtitle () {
    xprop -id $WINDOWID -set WM_NAME "$*"
}

dusum () {
    ls | sed -e 's, ,\\ ,g; s,-,\\-,g;' | xargs du -s | sort -n | cut -d'	' -f2 | sed -e's, ,\\ ,g; s,-,\\-,g;' | xargs du -sh
}

ac_fix_unquoted_ac_defun () {
    find . -name \*.m4|for i in `cat`; do sed -i 's/^AC_DEFUN(\([^\[,]*\),/AC_DEFUN([\1],/g' $i; done
}

ac_run_autoupdates () {
    find . -name configure.in -o -name configure.ac | for i in `cat`; do
        (
            dir=`dirname $i`
            echo autoupdating in $dir
            mv aclocal.m4 aclocal.m4.old
            autoupdate -f
        )
    done
}


printdayinfo () {
    day=$1
    if test -z "$day"; then return 1; fi
    ( while read dayname desc; do
            if [ "$day" = "$dayname" ]; then
                echo $day $desc | fmt
            fi
        done ) <<END
Sunday		sucks, because tomorrow is monday.
Monday		is when everything breaks for no apparent reason, creating so many problems it takes you until friday to get back to normal.
Tuesday		sucks, because it follows monday.
Wednesday	sucks, because it is only half way through the week.
Thursday	sucks, because it isnt friday.
Friday		sucks, because it should be the weekend, but you're stuck working anyway.
Saturday	is the only day of the week that doesn't suck.
END
    return 0
}

scr_settitle () {
    unset PROMPT_COMMAND
    echo -e "\033k\033\134\$ $1"
}

setup_interactive () {
    export SHELL
    eval `dircolors`
    alias ls='ls --color=auto -a -p'
    case $TERM in
    rxvt*|Xterm|xterm|aterm|urxvt*)
        XTERM_SET='\[\033]0;\u@\h:\w\007\]'
        ;;
    *)
        XTERM_SET=''
        ;;
    esac
    if [ -n "$CLEARCASE_ROOT" ]; then
        CCASE="[`echo $CLEARCASE_ROOT|cut -d/ -f3`]"
        VOBPATH="`cleartool lsvob|grep ^*|awk '{print $2}'|head -1|xargs dirname`"
        cd $VOBPATH
    fi
    if [ -n "$VIM" ]; then
        INVIM="[vim]"
    fi
    PS1="$XTERM_SET\[\033[0;36m\]\u@\h\[\033[1;00m\]
$CCASE$INVIM\w\$ "
    export PROMPT_COMMAND='echo -n -e "\033k\033\134"'
    [ -z "$day" ] && day=`date +%A`
    printdayinfo $day
    unset XTERM_SET CCASE VOBPATH INVIM

    if [ -z "$TERMCAP" ]; then
        # Deal with missing terminal types on certain machines.
        _c="`echo $TERM|sed -e's,^\(.\).*$,\1,'`"
        if ! test -e /usr/share/terminfo/$_c/$TERM &&
            ! test -e $HOME/.terminfo/$_c/$TERM; then
            TERM=rxvt
        else
            # ugh, damn old termcap based applications
            infocmp -C > $HOME/.termcap 2>/dev/null
            TERMCAP="$HOME/.termcap"
        fi
        unset _c
    elif [ "$TERM" = "screen" -o "$TERM" = "screen-bce" ]; then
        # Terminfo entries for screen are static, and don't seem to adapt when
        # screen is built with 256 color support... so... generate a new one
        # based on the TERMCAP variable that screen sets. (NOTE: stock screen
        # doesn't adjust the Co value in the TERMCAP env var to the number of
        # colors it was built to support. I have a patch to fix that.)
        mkdir -p $HOME/.terminfo/s
        captoinfo > $HOME/.terminfo/s/$TERM 2>/dev/null
        tic $HOME/.terminfo/s/$TERM 2>/dev/null
    fi

    export TERM TERMCAP
}

e () {
    [ -d SCCS ] && get -e $* >/dev/null 2>&1 <&1
    $EDITOR "$@"
}

find_agent () {
    local pid sock
    pid="`ps aux|grep ssh-agent|grep -v grep|awk '{print $2}'`"
    if [ -z "$pid" ]; then
        echo >&2 "Unable to locate ssh-agent process.  Aborting."
        return 1
    fi
    sock="`ls /tmp/ssh-*/agent.*|head -n 1`"
    SSH_AGENT_PID="$pid"
    SSH_AUTH_SOCK="$sock"
    export SSH_AGENT_PID SSH_AUTH_SOCK
}

fixperms () {
    path="$1"
    if [ -z "$path" ]; then path='.'; fi
    find $path -type f -exec chmod 644 {} \;; find . -type d -exec chmod 755 {} \;
}

pager () {
    $PAGER "$@"
}

foo () {
    local temp="`mktemp -q $HOME/foo.XXXXXX`"
    if [ $? -ne 0 ]; then
        echo >&2 "Unable to create temporary file.  Aborting."
        return 1
    fi
    e "$temp"
    if [ "`/bin/ls -l \"$temp\"|awk '{print $5}'`" = "0" ]; then
        rm -f "$temp"
    fi
}

# Kill off the dead checkouts
svk_purgeco () {
    svk co -l|grep ^?|awk '{print $3}'|for i in `cat`; do svk co --detach $i; done
}

svk_updateco () {
    svk co -l|grep -v ^?|awk '{print $3}'|for i in `cat`; do svk up $i; done
}

# Used to vim..
:make () {
    make "$@"
    return $?
}

if [ "$PS1" ]; then
    setup_interactive
fi

alias diff='diff -urNdp'
alias glxgears='glxgears -printfps'
#alias fgl_glxgears='fgl_glxgears -fbo'
alias vi='vim'
alias symbolsizes="${NM} -S -t d --size-sort"
alias lr='ls --sort=time --reverse'
alias ct='cleartool'
alias cpe='clearprojexp'
alias hd='od -t x1'
alias mtn='monotone'
alias bb='bitbake'
alias vim='vim -X'

if [ -n "$BASH" ]; then
    # If a hashed item from the path no longer exists, search the PATH again.
    # This is helpful, say, if you remove the /usr/local/bin/foo, and want it to
    # immediately fall back to /usr/bin/foo, rather than erroring.
    shopt -s checkhash

    # Automatically check and adjust the window size after executing a command.
    # Helpful when resizing your terminal.
    shopt -s checkwinsize

    # Don't complete using the PATH when hitting the completion character on an
    # empty line (seeing a list of every binary in the system isn't exactly
    # useful).
    shopt -s no_empty_cmd_completion

    # Use programmable completion
    shopt -s progcomp

    # Tab completion for GNU make targets
    maketargets() {
        local cur
        cur=${COMP_WORDS[COMP_CWORD]}
        if [ -e makefile -o -e Makefile ]; then
            COMPREPLY=($(make -qpi 2>/dev/null | sed -n -e '/^[#.]/b; /=/b; /:$/{s/\(.*\):/\1/; /%/{/%$/{p;}; b;}; p}'))
            COMPREPLY=($(compgen -W '${COMPREPLY[@]}' -- $cur))
        else
            COMPREPLY=($(compgen -A file -- $cur))
        fi
    }
    complete -F maketargets make gmake
fi
