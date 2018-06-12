if (( $+commands[vim] )); then
    alias vi=vim
fi

if [[ $OSTYPE =~ darwin ]] && (( $+commands[mvim] )); then
    if [[ -n $VIM_SERVER ]] && vim --version 2>/dev/null | grep -qw '+clientserver'; then
        alias vim="mvim -v --servername $VIM_SERVER --remote"
    else
        alias vim='mvim -v'
    fi
elif [[ -n $VIM_SERVER ]] && vim --version 2>/dev/null | grep -qw '+clientserver'; then
    alias vim="vim --servername $VIM_SERVER --remote"
fi
