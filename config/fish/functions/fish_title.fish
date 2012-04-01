# https://github.com/zong-sharo
function fish_title
    if begin set -q TMUX; or set -q fish_title_disabled; end
        return
    end

    set -l job
    if test $_ != fish
        set job "$_ - "
    end

    set -g fish_title_string (printf '%s%s:%s' "$job" $HOSTNAME $PWD)
    echo $fish_title_string
end
