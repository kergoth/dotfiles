if [[ "$OSTYPE" = "WSL" ]]; then
    export BROWSER="cmd.exe /C START"
    if [[ -z "$USERPROFILE" ]]; then
        if (( $+commands[cmd.exe] )); then
            export USERPROFILE="$(wslpath "$(cmd.exe /D /C 'SET /P <NUL=%USERPROFILE%' 2>/dev/null)")"
        else
            echo >&2 "Error: cmd.exe not available, and USERPROFILE is not set"
        fi
    fi

    path=("$USERPROFILE/Apps/npiperelay" $path)
    if (( $+commands[npiperelay.exe] )); then
        if (( $+commands[socat] )); then
            export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
            if ! ss -a | grep -q "$SSH_AUTH_SOCK" || ! pgrep -f socat &>/dev/null; then
                rm -f "$SSH_AUTH_SOCK"
                ( setsid socat "UNIX-LISTEN:$SSH_AUTH_SOCK,fork" EXEC:"${commands[npiperelay.exe]} -ei -s //./pipe/openssh-ssh-agent",nofork & )
            fi
        else
            echo >&2 "Warning: socat is not installed, unable to use npiperelay to connect to Windows SSH agent."
        fi
    fi

    if [[ -o interactive ]] && [[ $PWD = $USERPROFILE ]]; then
        cd
    fi
fi
