case "$(uname -r)" in
    *-Microsoft|*-microsoft-*)
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
        USERPROFILE="${USERPROFILE:-$(wslpath "$(cmd.exe /D /C 'SET /P <NUL=%USERPROFILE%' 2>/dev/null)")}"

        export BROWSER="cmd.exe /C START"
        if [[ -z "$SSH_AUTH_SOCK" ]] && [[ -n "$WSL_AUTH_SOCK" ]]; then
            export SSH_AUTH_SOCK=$WSL_AUTH_SOCK
        fi
        ;;
esac
