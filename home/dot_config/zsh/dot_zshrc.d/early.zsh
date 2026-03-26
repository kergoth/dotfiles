if [[ -z $DOTFILES_NO_UPDATE ]]; then
    DOTFILES_STAMP=$XDG_CACHE_HOME/zsh/dotfiles-updated
    old_stamps=( $DOTFILES_STAMP(N.mh+14) )
    if [[ -e ~/.local/share/chezmoi/.git ]] && { (( ${#old_stamps} )) || [[ ! -f $DOTFILES_STAMP ]]; }; then
        echo >&2 "Checking for dotfiles updates (once daily)"
        _dotfiles_updated=0
        pushd -q ~/.local/share/chezmoi
        if git fetch --quiet 2>/dev/null; then
            if [[ "$(git rev-list --count HEAD..@{u} 2>/dev/null)" -gt 0 ]]; then
                echo >&2 "Dotfiles have updates, pulling..."
                if git pull --quiet && chezmoi apply; then
                    _dotfiles_updated=1
                fi
            fi
        fi
        popd -q
        touch "$DOTFILES_STAMP"
        if (( _dotfiles_updated )); then
            echo >&2 "Restarting zsh for dotfiles updates"
            if (( $+commands[direnv] )); then
                exec direnv exec "$HOME" zsh --login
            else
                exec zsh --login
            fi
        fi
    fi
fi

if [[ -e "$XDG_CONFIG_HOME/vim" ]] && [[ -z $VIM_NO_UPDATE ]]; then
    VIM_STAMP=$XDG_CACHE_HOME/zsh/vim-updated
    old_stamps=( $VIM_STAMP(N.mh+160) )
    if [[ -e "$XDG_CONFIG_HOME/vim/.git" ]] && { (( ${#old_stamps} )) || [[ ! -f $VIM_STAMP ]]; }; then
        echo >&2 "Checking for vim updates (once weekly)"
        pushd -q "$XDG_CONFIG_HOME/vim"
        if git fetch --quiet 2>/dev/null; then
            if [[ "$(git rev-list --count HEAD..@{u} 2>/dev/null)" -gt 0 ]]; then
                echo >&2 "Vim repository has updates, pulling..."
                git pull --quiet
            fi
        fi
        popd -q
        if [ -e "$XDG_CONFIG_HOME/vim/script/bootstrap" ]; then
            "$XDG_CONFIG_HOME/vim/script/bootstrap" && touch "$VIM_STAMP"
        fi
    fi
fi

if [[ ! -e /.dockerenv ]]; then
    case "$(uname -r)" in
        *-microsoft-*)
            OSTYPE=WSL
            ;;
    esac
fi

if [[ "$OSTYPE" = WSL ]] && [[ -o interactive ]]; then
    UID=${UID:-$(id -u)}
    if ! [[ -d /run/user/"$UID" ]]; then
        if (( ${+commands[doas]} )); then
            echo >&2 "Warning: /run/user/$UID does not exist. Creating using doas."
            doas bash -c "mkdir -p /run/user/\"$UID\" && chown -R \"$UID\" /run/user/\"$UID\""
        else
            echo >&2 "Warning: /run/user/$UID does not exist. Creating using sudo."
            sudo mkdir -p /run/user/"$UID" && \
                sudo chown -R "$UID" /run/user/"$UID"
        fi
    fi
    if [[ -d /mnt/wslg/runtime-dir ]] && ! [[ -e /run/user/"$UID"/wayland-0 ]]; then
        ln -sf /mnt/wslg/runtime-dir/* /run/user/"$UID"/
    fi
fi

if (( ${+commands[direnv]} )); then
    eval "$(direnv export zsh)"
fi
