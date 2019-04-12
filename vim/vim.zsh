if (( $+commands[vim] )); then
    alias vi=vim
fi

if [[ -n $VIM_SERVER ]] && vim --version 2>/dev/null | grep -qw '+clientserver'; then
    alias vim="vim --servername $VIM_SERVER --remote"
fi
