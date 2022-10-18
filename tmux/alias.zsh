if (( $+commands[direnv] )); then
    alias tmux='direnv exec / tmux -u2 -f ~/.config/tmux/config'
else
    alias tmux='tmux -u2 -f ~/.config/tmux/config'
fi
