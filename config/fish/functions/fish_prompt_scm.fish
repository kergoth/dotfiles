if not set -q fish_color_scm_dirty
    set -g fish_color_scm_dirty $fish_color_operator
end
if not set -q fish_color_scm_git
    set -g fish_color_scm_git green
end
if not set -q fish_color_scm_mercurial
    set -g fish_color_scm_mercurial purple
end

function fish_prompt_scm -d 'SCM state information for the prompt'
    if not set -q __fish_prompt_scm_dirty
        set -g __fish_prompt_scm_dirty (set_color $fish_color_scm_dirty)
    end

    set -l git (prompt-git)
    if test $git
        if not set -q __fish_prompt_scm_git
            set -g __fish_prompt_scm_git (set_color $fish_color_scm_git)
        end
        printf ' %s%s%s%s' $__fish_prompt_scm_dirty (prompt-git-dirty) $__fish_prompt_scm_git $git
    end

    set -l hg (prompt-hg)
    if test $hg
        if not set -q __fish_prompt_scm_mercurial
            set -g __fish_prompt_scm_mercurial (set_color $fish_color_scm_mercurial)
        end
        printf ' %s%s%s%s' $__fish_prompt_scm_dirty (prompt-hg-dirty) $__fish_prompt_scm_mercurial $hg
    end
end
