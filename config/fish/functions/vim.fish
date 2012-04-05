function vim_tmux
    set automatic_rename (tmux show-options -w|sed -n 's/^automatic-rename //p')
    if test -z "$automatic_rename"
        set automatic_rename (tmux show-options -gw|sed -n 's/^automatic-rename //p')
    end

    if test "$automatic_rename" = on
        command vim $argv
        tmux setw automatic-rename on >/dev/null
    else
        set window_name (tmux lsw -F '#{window_active}:#{window_name}'|sed -n 's/^1://p')
        command vim $argv
        tmux rename-window $window_name
    end
end

function vim
    if not tmux ls 2>/dev/null
        command vim $argv
    else
        vim_tmux $argv
    end
end
