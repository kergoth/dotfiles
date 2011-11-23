# https://github.com/zong-sharo
function fish_title
    if set -q fish_title_disabled
        return
    end

    if test $_ != fish
        set -l job $_
    end
        
    set -gx fish_title_string (printf '%s:%s %s' $HOSTNAME $PWD $job)
    echo $fish_title_string
end
