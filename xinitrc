#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

# If we have a proxy config file, use it
if [[ -e ~/.proxy.pac ]]; then
    export auto_proxy=file://$HOME/.proxy.pac
fi

vmware-user-suid-wrapper
autocutsel -fork &
autocutsel -selection PRIMARY -fork &

if [ -e ~/.Xresources ]; then
    xrdb ~/.Xresources
fi

exec ssh-agent sscrotwm
