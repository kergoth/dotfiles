if [[ $OSTYPE =~ darwin ]]; then
    if ! [[ -e $XDG_CACHE_HOME/zsh/xcrun ]]; then
        xcrun --show-sdk-path >$XDG_CACHE_HOME/zsh/xcrun
    fi
    export CFLAGS="$CFLAGS -I$(<$XDG_CACHE_HOME/zsh/xcrun)/usr/include"
fi
