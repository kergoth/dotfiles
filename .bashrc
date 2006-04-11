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
	if [ -n "$COLORTERM" ]; then
		alias ls='ls --color=always -a -p'
	else
		eval `dircolors`
		alias ls='ls --color=auto -a -p'
	fi
	case $TERM in
	rxvt*|Xterm|xterm|aterm|urxvt*)
		XTERM_SET='\[\033]0;\u@\h:\w\007\]'
	;;
	*)
		XTERM_SET=''
	;;
	esac
    if [ -n "$CLEARCASE_ROOT" ]; then
        CCASE="[`echo $CLEARCASE_ROOT|cut -d/ -f3`]";
        VOBPATH="`cleartool lsvob|grep ^*|awk '{print $2}'|head -1|xargs dirname`";
        cd $VOBPATH;
    fi;
    PS1="$XTERM_SET\[\033[0;36m\]\u@\h\[\033[1;00m\]
$CCASE\w\$ ";
    export PROMPT_COMMAND='echo -n -e "\033k\033\134"';
    [ -z "$day" ] && day=`date +%A`;
    printdayinfo $day;
    XTERM_SET='';
    CCASE='';
    VOBPATH=''
}

e () {
	[ -d SCCS ] && get -e $* >/dev/null 2>&1 <&1
	$EDITOR "$@"
}

#e () {
#	bk editor $*
#}

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

if [ "$PS1" ]; then
	setup_interactive
fi

alias diff='diff -urNdp'
alias glxgears='glxgears -printfps'
#alias fgl_glxgears='fgl_glxgears -fbo'
alias vi=vim
alias ssh-add='ssh-add ~/.ssh/{identity,*dsa,*rsa1,*rsa2} ~/.ssh/old/*'
alias symbolsizes="${NM} -S -t d --size-sort"
alias ct='cleartool'
alias cpe='clearprojexp'
alias lr='ls --sort=time --reverse'

if test x"$TERM" = "xrxvt-unicode"; then
	c="`echo $TERM|sed -e's,^\(.\).*$,\1,'`"
	if ! test -e /usr/share/terminfo/$c/$TERM &&
	   ! test -e $HOME/.terminfo/$c/$TERM; then
		TERM=rxvt
	fi
fi

export TERM
