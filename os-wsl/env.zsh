case "$(uname -r)" in
    *-Microsoft)
        OSTYPE=WSL
        if [[ ! -v WslDisks ]]; then
            if [[ -e /etc/wsl.conf ]]; then
                WslDisks="$(sed -n -e 's/^root = //p' /etc/wsl.conf)"
                if [[ -n $WslDisks ]]; then
                    export WslDisks="${WslDisks%/}"
                else
                    unset WslDisks
                fi
            fi
        fi
        USERPROFILE="${USERPROFILE:-$(wslpath "$(cmd.exe /D /C 'SET /P <NUL=%USERPROFILE%' 2>/dev/null)")}"

        export BROWSER="cmd.exe /C START"
        if [[ -z "$SSH_AUTH_SOCK" ]] && [[ -n "$WSL_AUTH_SOCK" ]]; then
            if SSH_AUTH_SOCK=$WSL_AUTH_SOCK ssh-add -l >/dev/null 2>&1; then
                export SSH_AUTH_SOCK=$WSL_AUTH_SOCK
            fi
        fi
        ;;
esac
