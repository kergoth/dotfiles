export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH}

if [ -e /usr/lib/locale/locale-archive ]; then
    export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
fi

export XDG_DATA_DIRS=$HOME/.nix-profile/share:${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}
