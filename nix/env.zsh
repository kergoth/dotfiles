export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH}

if [ -e ~/.nix-profile/lib/locale/locale-archive ]; then
    export LOCALE_ARCHIVE="$HOME/.nix-profile/lib/locale/locale-archive"
elif [ -e /usr/lib/locale/locale-archive ]; then
    export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
fi
