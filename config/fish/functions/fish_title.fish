# https://github.com/zong-sharo
function fish_title
    if test $_ != 'fish'
        set -l job $_
    end
        
    set -gx fish_title_string (printf '%s:%s %s' (hostname|cut -d . -f 1) (pwd) $job)
    echo $fish_title_string
end

if begin test $TERM = 'screen'; or test $TERM = 'screen-256color'; end
    function screen_title --on-variable fish_title_string # damn hack
        printf '\033k%s\033\\' $fish_title_string
    end
end
