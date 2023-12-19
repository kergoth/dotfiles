# local oldtime=$REPORTTIME
# unset REPORTTIME
# if [[ -z $DOTFILES_NO_UPDATE ]]; then
#     DOTFILES_STAMP=$XDG_CACHE_HOME/zsh/dotfiles-updated
#     if [[ -e "$DOTFILESDIR/.git" ]] && [[ -n $DOTFILES_STAMP(#qN.mh+14) ]] || [[ ! -f $DOTFILES_STAMP ]]; then
#         echo >&2 "Checking for dotfiles updates (once daily)"
#         "$DOTFILESDIR"/script/sync && touch "$DOTFILES_STAMP"
#     fi
# fi
# if [[ -e "$DOTFILESDIR/vim" ]] && [[ -z $VIM_NO_UPDATE ]]; then
#     VIM_STAMP=$XDG_CACHE_HOME/zsh/vim-updated
#     if [[ -e "$DOTFILESDIR/vim/.git" ]] && [[ -n $VIM_STAMP(#qN.mh+160) ]] || [[ ! -f $VIM_STAMP ]]; then
#         echo >&2 "Checking for vim updates (once weekly)"
#         if [ -e "$DOTFILESDIR"/vim/script/bootstrap ]; then
#             "$DOTFILESDIR"/vim/script/bootstrap && touch "$VIM_STAMP"
#         fi
#     fi
# fi
# if [[ -n "$oldtime" ]]; then
#     REPORTTIME="$oldtime"
# else
#     unset REPORTTIME
# fi
