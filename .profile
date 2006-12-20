umask 022

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

. ~/.sh/env
. ~/.sh/volatile
