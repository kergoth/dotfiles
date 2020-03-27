if [[ -z $DOTFILES_NO_UPDATE ]]; then
    DOTFILES_STAMP=$XDG_CACHE_HOME/zsh/dotfiles-updated
    if [[ -n $DOTFILES_STAMP(#qN.mh+24) ]] || [[ ! -f $DOTFILES_STAMP ]]; then
        (
            cd $DOTFILESDIR || exit 1
            if [ -e .mrconfig ]; then
                echo >&2 "Checking for dotfiles updates (once daily)"
                mr update
            elif [ -e .git ]; then
                echo >&2 "Checking for dotfiles updates (once daily)"
                git pull
                if [ -e vim/.git ]; then
                    ( cd vim && git pull )
                fi
            fi
            if [[ -e vim/script/bootstrap ]]; then
                ./vim/script/bootstrap || :
            fi
        )
        touch $DOTFILES_STAMP
    fi
fi
