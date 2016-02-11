if [[ $OSTYPE =~ darwin ]]; then
    export CFLAGS="$CFLAGS -I$(xcrun --show-sdk-path)/usr/include"
fi
