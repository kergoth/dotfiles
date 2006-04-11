umask 022

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

for p in ~/.root/bin ~/bin; do
	if [ -d $p ]; then
		PATH="$p:$PATH"
	fi
done

for p in ~/.root/share/man ~/man; do
	if [ -d $p ]; then
		MANPATH="$p:$MANPATH"
	fi
done

PATH="${PATH}:/usr/local/sbin:/usr/sbin:/sbin"
PAGER="less -seGiq"
EDITOR="vim"
BK_USER="kergoth"
[ -z "${NM}" ] && NM="nm"
LUA_INIT="@${HOME}/.lua/init.lua"
CCACHE_DIR="${HOME}/.ccache"
HISTFILE="${HOME}/.bash_history"
TERMINFO="${HOME}/.terminfo"

export PATH MANPATH PAGER EDITOR
export BK_USER NM LUA_INIT
export CCACHE_DIR HISTFILE TERMINFO
