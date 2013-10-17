function set_title -d "Set terminal title"
    set -g fish_title_override "$argv"
    # set -g fish_title_disabled

    # if begin set -q STY; or set -q TMUX; end
    #     printf "\033k%s\033\\" $argv
    # else
    #     printf "\033]0;%s\007" $argv
    # end
end
