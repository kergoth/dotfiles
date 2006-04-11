# ~/.bash_profile: executed by bash(1) for login shells.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

umask 022

echo

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# set PATH so it includes user's private bin if it exists
if [ -d ~/bin ] ; then
    PATH=~/bin:"${PATH}"
fi

# do the same with MANPATH
if [ -d ~/man ]; then
    MANPATH=~/man:"${MANPATH}"
fi

PATH="/usr/local/sbin:/usr/sbin:/sbin:${PATH}"
PAGER="less -seGiq"
EDITOR="vim"
BK_USER="kergoth"
[ -z "${NM}" ] && NM=nm
LUA_INIT="@${HOME}/.lua/init.lua"

if test x"$TERM" = "xrxvt-unicode"; then
	c="`echo $TERM|sed -e's,\(.\).*,\1,'`"
	if ! test -e /usr/share/terminfo/$c/$TERM; then
		TERM=rxvt
	fi
fi

export PATH MANPATH PAGER EDITOR
export BK_USER NM LUA_INIT TERM
