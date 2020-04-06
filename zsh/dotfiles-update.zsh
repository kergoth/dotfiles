local oldtime=$REPORTTIME
unset REPORTTIME
if [[ -z $DOTFILES_NO_UPDATE ]]; then
    DOTFILES_STAMP=$XDG_CACHE_HOME/zsh/dotfiles-updated
    if [[ -e "$DOTFILESDIR/.git" ]] && [[ -n $DOTFILES_STAMP(#qN.mh+24) ]] || [[ ! -f $DOTFILES_STAMP ]]; then
        echo >&2 "Checking for dotfiles updates (once daily)"
        "$DOTFILESDIR"/script/sync
    fi
fi
if [[ -n "$oldtime" ]]; then
    REPORTTIME="$oldtime"
else
    unset REPORTTIME
fi
