if begin test $TERM = 'screen'; or test $TERM = 'screen-256color'; end
    function screen_title --on-variable fish_title_string # damn hack
        printf '\033k%s\033\\' $fish_title_string
    end
end
