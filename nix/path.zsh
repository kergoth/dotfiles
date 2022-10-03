if [ -d ~/.nix ] && ! [ -d /nix ]; then
    home_nix=1
else
    home_nix=
fi

if [ -e ~/.nix-profile/etc/profile.d/nix-daemon.sh ]; then
    . ~/.nix-profile/etc/profile.d/nix-daemon.sh
elif [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
    . ~/.nix-profile/etc/profile.d/nix.sh
elif [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix.sh'
fi

path=(~/.nix/shims $path)
