if [ -r ~/.bashrc ]; then
    source ~/.bashrc
fi

. ~/.sh/env

if [ -r ~/.sh/volatile.$HOSTNAME ]; then
    . ~/.sh/volatile.$HOSTNAME
fi

cd $HOME
