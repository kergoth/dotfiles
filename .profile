if [ -n "$BASH" -a -r ~/.bashrc ]; then
    . ~/.bashrc
fi

if [ -n "$debian_chroot" ]; then
    HOSTNAME=$HOSTNAME.$debian_chroot
fi

. ~/.sh/env

if [ -r ~/.sh/firstinteractive ]; then
    . ~/.sh/firstinteractive
fi

if [ -r ~/.sh/volatile.$HOSTNAME ]; then
    . ~/.sh/volatile.$HOSTNAME
fi

cd $HOME
