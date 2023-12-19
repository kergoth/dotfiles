if [[ "$OSTYPE" = "WSL" ]]; then
    OSTYPE=WSL
    if [[ -z "$WslDisks" ]]; then
        export WslDisks=/mnt
        if [[ -e /etc/wsl.conf ]]; then
            WslDisks="$(sed -n -e 's/^root = //p' /etc/wsl.conf)"
            if [[ -n $WslDisks ]]; then
                export WslDisks="${WslDisks%/}"
            else
                WslDisks=/mnt
            fi
        fi
    fi
    export BROWSER="cmd.exe /C START"
fi

if [[ -o interactive ]] && [[ $OSTYPE = WSL ]] && [[ $PWD = $USERPROFILE ]]; then
    cd
fi
