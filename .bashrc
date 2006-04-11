oedev () {
	local OEDIR PKGDIR BUILDDIR
	if test x"$1" = "x--help"; then echo >&2 "syntax: oedev [oedir [pkgdir [builddir]]]"; return 1; fi
	if test x"$1" = x; then OEDIR=`pwd`; else OEDIR=$1; fi
	if test x"$2" = x; then PKGDIR=`pwd`; else PKGDIR=$2; fi
	if test x"$3" = x; then BUILDDIR=`pwd`; else BUILDDIR=$3; fi

	OEDIR=`readlink -f $OEDIR`
	PKGDIR=`readlink -f $PKGDIR`
	BUILDDIR=`readlink -f $BUILDDIR`
	if ! (test -d $OEDIR && test -d $PKGDIR && test -d $BUILDDIR); then
		echo >&2 "syntax: oedev [oedir [pkgdir [builddir]]]"
		return 1
	fi

	PATH=$OEDIR/bin:$PATH
	OEPATH=$OEDIR
	if test x"$OEDIR" != x"$PKGDIR"; then
		OEPATH=$PKGDIR:$OEPATH
	fi
	if test x"$PKGDIR" != x"$BUILDDIR"; then
		OEPATH=$BUILDDIR:$OEPATH
	fi
	export OEPATH
}

oefiles () {
	export OEFILES=`ls $PKGDIR/*/*.oe|grep -v -E "$OEMASK"`
}

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
			echo $day $desc
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
	PS1="$XTERM_SET\[\033[0;36m\]\u@\h\[\033[1;00m\]
\w\$ "
	export PROMPT_COMMAND='echo -n -e "\033k\033\134"'
	[ -z "$day" ] && day=`date +%A`
	printdayinfo $day
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

checkthefuckerin() {
	(
	addon="$1"
	version="$2"
	svk add *
	svk ci -m "Import $1 version $2."
	cd ..
	svk cp current "$2"
	svk ci -m "Tag $1 version $2."
	svk cp current ../../trunk/KergothWOWBits/Addons/$1
	svk ci -m "Add $1 to the addon set." ../../trunk/KergothWOWBits/Addons/$1
	)
}

updatethefucker() {
	(
	addon="$1"
	version="$2"
	dir="$3"
	svn_load_dirs -t vendor/$addon/$version file:///var/lib/svn/KergothWOWBits vendor/$addon/current $dir
	svk pull
	if [ "$4" != "nomerge" ]; then
		svk smerge -m "Update $addon to version $version." //WOW/vendor/$addon/current //WOW/trunk/KergothWOWBits/Addons/$addon
	fi
	)
}

fixperms () {
	path="$1"
	if [ -z "$path" ]; then path='.'; fi
	find $path -type f -exec chmod 644 {} \;; find . -type d -exec chmod 755 {} \;
}

wow_addon () {
	# Shell function to:
	# 1) Extract the addon's .zip
	# 2) Use the addon's .toc file to locate the addon sources in the extracted zip tree
	# 3) Import those sources into /vendor/$addon/current
	# 4) Tag /vendor/$addon/current as /vendor/$addon/$version
	# 5) Merge changes from /vendor/$addon/current to /trunk/KergothWOWBits/Addons/$addon
	addon="$1"
	version="$2"
	zip="$3"
	if [ ! -e "$zip" ]; then
		echo >&2 "ERROR: $zip not found."
		return 1
	fi
	if [ -z "$addon" -o -z "$version" ]; then
		echo >&2 "Syntax: $0 ADDON VERSION ZIPFILE"
		return 1
	fi

	svk ls "/WOW/vendor/$addon/$version" >/dev/null 2>&1
	if [ "$?" == "0" ]; then
		echo "vendor/$addon/$version already exists.  aborting."
		mkdir -p "~/Addons/$addon"
		mv $zip "~/Addons/$addon/"
		return 0
	fi

	TMPDIR="`mktemp -d /tmp/$addon.XXXXXX`" || (echo >&2 "ERROR: Unable to create temporary directory"; exit 1)

	OLDDIR="`pwd`"
	if ! (echo $zip|grep -q '^/'); then
		zip="$OLDDIR/$zip"
	fi

	cd "$TMPDIR"
	unzip "$zip"
    find . -name CVS -o -name \.svn | xargs rm -rf
	tocfile="`find . -name \*.toc|grep -E \"$addon/[^/]+.toc\"`"
	if [ ! -e "$tocfile" ]; then
		echo >&2 "ERROR: Unable to locate .toc file."
		cd $OLDDIR
		return 1
	fi

	tocpath=`dirname "$tocfile"`
	fixperms "$tocpath"

	#svk mkdir -p -m "Create necessary dirs for the import of $addon version $version." //WOW/vendor/$addon/current
	#svk import -m "Import version $version of $addon." //WOW/vendor/$addon/current "$tocpath"
	#svk cp -m "Tag version $version of $addon." //WOW/vendor/$addon/current //WOW/vendor/$addon/$version
	svn_load_dirs -t vendor/$addon/$version file://$HOME/.svk/local/WOW "vendor/$addon/current" "$tocpath"
	svk sync //WOW
	if [ "$4" != "nomerge" ]; then
		svk smerge -m "Update $addon to version $version." //WOW/vendor/$addon/current //WOW/trunk/KergothWOWBits/Addons/$addon
	fi

	cd $OLDDIR

	#mkdir -p "~/Addons/$addon"
	#mv "$zip" "~/Addons/$addon/"

	rm -rf "$TMPDIR"

	return 0
}

if [ "$PS1" ]; then
	setup_interactive
fi

alias glxgears='glxgears -printfps'
#alias fgl_glxgears='fgl_glxgears -fbo'
alias vi=vim
alias diff='diff -urNd'
alias ssh-add='ssh-add ~/.ssh/{identity,*dsa,*rsa1,*rsa2} ~/.ssh/old/*'
alias symbolsizes="${NM} -S -t d --size-sort"
