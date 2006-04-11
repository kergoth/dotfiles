# ~/.bash_profile: executed by bash(1) for login shells.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

umask 022

echo

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

for p in ~/.root/bin ~/bin; do
    if [ -d $p ] ; then
        PATH=$p:"${PATH}"
    fi
done

for p in ~/.root/man ~/man; do
    if [ -d $p ]; then
        MANPATH=$p:"${MANPATH}"
    fi
done

PATH="${PATH}:/usr/local/sbin:/usr/sbin:/sbin"
PAGER="less -seGiq"
EDITOR="vim"
BK_USER="kergoth"
[ -z "${NM}" ] && NM=nm
LUA_INIT="@${HOME}/.lua/init.lua"
CCACHE_DIR="${HOME}/.ccache"
HISTFILE="${HOME}/.bash_history"
TERMINFO="${HOME}/.terminfo"

export PATH MANPATH PAGER EDITOR
export BK_USER NM LUA_INIT
export CCACHE_DIR HISTFILE TERMINFO
