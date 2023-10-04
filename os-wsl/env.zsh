if [[ ! -e /.dockerenv ]]; then
    case "$(uname -r)" in
        *-Microsoft)
            OSTYPE=WSL
            WSLVER=1
            export USERPROFILE="${USERPROFILE:-$(wslpath "$(cmd.exe /D /C 'SET /P <NUL=%USERPROFILE%' 2>/dev/null)")}"
            if [[ -z "$SSH_AUTH_SOCK" ]] && [[ -n "$WSL_AUTH_SOCK" ]]; then
                export SSH_AUTH_SOCK=$WSL_AUTH_SOCK
            fi
            ;;
        *-microsoft-*)
            OSTYPE=WSL
            WSLVER=2
            export USERPROFILE="${USERPROFILE:-$(wslpath "$(cmd.exe /D /C 'SET /P <NUL=%USERPROFILE%' 2>/dev/null)")}"
            if [[ -z "${NPIPERELAY:-}" ]]; then
                for i in "$USERPROFILE/Apps/npiperelay/npiperelay.exe" "$USERPROFILE/scoop/apps/npiperelay/current/npiperelay.exe"; do
                    if [[ -e "$i" ]]; then
                        NPIPERELAY="$i"
                        break
                    fi
                done
            fi
            if [[ -e "${NPIPERELAY:-}" ]]; then
                if (( $+commands[socat] )); then
                    export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
                    if ! ss -a | grep -q "$SSH_AUTH_SOCK"; then
                        rm -f "$SSH_AUTH_SOCK"
                        ( setsid socat "UNIX-LISTEN:$SSH_AUTH_SOCK,fork" EXEC:"$NPIPERELAY -ei -s //./pipe/openssh-ssh-agent",nofork & )
                    fi
                else
                    echo >&2 "Warning: socat is not installed, unable to use npiperelay for ssh auth sock"
                fi
            fi
            ;;
    esac
fi

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
