if [[ ! -e /.dockerenv ]]; then
    case "$(uname -r)" in
        *-microsoft-*)
            OSTYPE=WSL
            ;;
    esac
fi

if [[ "$OSTYPE" = WSL ]]; then
    UID=${UID:-$(id -u)}
    if ! [[ -d /run/user/"$UID" ]]; then
        echo >&2 "Warning: /run/user/$UID does not exist. Creating using sudo."
        sudo mkdir -p /run/user/"$UID" && \
            sudo chown -R "$UID" /run/user/"$UID"
    fi
fi

if (( ${+commands[direnv]} )); then
    if [ "$home_nix" = 1 ] && [ $commands[direnv] = $HOME/.nix/shims/direnv ]; then
        emulate zsh -c "$(nixrun direnv export zsh)"
    else
        emulate zsh -c "$(direnv export zsh)"
    fi
fi
