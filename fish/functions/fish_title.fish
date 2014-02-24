if begin set -q TERM_PROGRAM; and test $TERM_PROGRAM = Apple_Terminal; end
    function fish_title
        if set -q DTACH_SESSION
            return
        end

        printf $HOSTNAME
        if set -q fish_title_override
            printf " — %s" $fish_title_override
        end

        set -l pwd (echo -n $PWD | sed 's/ /%20/g')
        printf '\a\033]7;file://localhost/%s' $pwd
    end
else
    function fish_title
        if set -q DTACH_SESSION
            return
        end

        if set -q fish_title_override
            set -g fish_title_string (printf "%s — %s" $fish_title_override $HOSTNAME)
        else
            set -l job
            if test $_ != fish
                set job "$_ - "
            end

            set -g fish_title_string (printf '%s%s:%s' "$job" $HOSTNAME (prompt_pwd))
        end
        echo $fish_title_string
    end
end

function fish_set_tab_title
    printf "\e]1;%s\a" "$argv"
end

function fish_set_window_title
    printf "\e]2;%s\a" "$argv"
end

function fish_set_screen_title
    printf "\ek%s\e\\" "$argv"
end
