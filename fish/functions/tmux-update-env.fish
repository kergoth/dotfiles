function tmux-update-env -d 'Update the current environment with variables from the tmux client'
    tmux showenv | begin
        set -lx IFS =
        while read var val
            if echo $var | grep -q '^-'
                set -l unsetvar (echo $var|cut -d- -f2-)
                eval set -e $unsetvar
            else
                eval set $var $val; or echo >&2 "Error setting "$var
            end
        end
    end
    return 0
end
