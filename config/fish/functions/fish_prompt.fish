if not set -q fish_color_identity
    set -g fish_color_identity cyan
end

# Based on https://github.com/abique/conf
function fish_prompt -d 'Write out the prompt'
    set -l old_status $status

    if not set -q __fish_prompt_normal
        set -g __fish_prompt_normal (set_color normal)
    end

    if test $old_status != 0
        printf '%s%s %s' (set_color $fish_color_error) $old_status $__fish_prompt_normal
    end

    if not set -q __fish_prompt_identity
        set -g __fish_prompt_identity (set_color $fish_color_identity)
    end
    if not set -q __fish_prompt_cwd
        set -g __fish_prompt_cwd (set_color $fish_color_cwd)
    end

    printf '%s%s@%s' $__fish_prompt_identity $USER $HOSTNAME
    if set -q SCHROOT_CHROOT_NAME
        printf '[%s]' $SCHROOT_CHROOT_NAME
    end
    printf ':%s%s' $__fish_prompt_cwd (prompt_pwd)

    fish_prompt_scm

    if not set -q __fish_prompt_operator
        set -g __fish_prompt_operator (set_color $fish_color_operator)
    end
    printf '%s> %s' $__fish_prompt_operator $__fish_prompt_normal
end
