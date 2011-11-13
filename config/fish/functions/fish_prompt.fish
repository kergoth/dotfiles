# Based on https://github.com/abique/conf
function fish_prompt -d 'Write the prompt'
    set -l old_status $status
    if test $old_status != 0
        printf '%s%s ' (set_color red) $old_status
    end

    printf '%s%s@%s:%s%s' (set_color cyan) (whoami) (hostname) (set_color normal) (prompt_pwd)

    set -l git (prompt-git)
    if test $git
        printf '%s %s' (set_color green) $git
    end
    set -l hg (prompt-hg)
    if test $hg
        printf '%s %s' (set_color purple) $hg
    end

    printf '%s> ' (set_color yellow)
    printf (set_color normal)
end
