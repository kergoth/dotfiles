umask 022

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

PATH="${HOME}/bin:${HOME}/.root/bin:${PATH}:/usr/local/sbin:/usr/sbin:/sbin"
PYTHONPATH="${HOME}/.root/lib/scons:${HOME}/.root/lib/python2.3"
MANPATH="${HOME}/man:${HOME}/.root/share/man:${MANPATH}"
PAGER="less -seGiq"
EDITOR="vim"
BK_USER="kergoth"
[ -z "${NM}" ] && NM="nm"
LUA_INIT="@${HOME}/.lua/init.lua"
CCACHE_DIR="${HOME}/.ccache"
HISTFILE="${HOME}/.bash_history"
TERMINFO="${HOME}/.terminfo"
VIMINFO="${HOME}/.viminfo"
SCONSFLAGS="-u"

export PATH MANPATH PAGER EDITOR PYTHONPATH
export BK_USER NM LUA_INIT CCACHE_DIR HISTFILE
export TERMINFO VIMINFO SCONSFLAGS
