# Handle some volatile files which you want in an alternate location. This can
# be useful when using an NFS home directory, or an SSD home directory if
# you're paranoid about unnecessary flash writes/erases.

if set -q VOLATILEPATH
    function set_volatile
        set -gx $argv[1] $VOLATILEPATH/$argv[2]
        if test -e ~/$argv[2]
            mv ~/$argv[2] $VOLATILEPATH/
        end
    end

    set_volatile CCACHE .ccache
    set_volatile VIMINFO .viminfo
    set_volatile LESSHISTFILE .lesshst

    # Note: this doesn't work, as fish will destroy the link and recreate the file
    #mkdir -p $VOLATILEPATH/.config/fish
    #if test -f ~/.config/fish/fish_history
    #    mv ~/.config/fish/fish_history $VOLATILEPATH/.config/fish/
    #end
    #ln -s $VOLATILEPATH/.config/fish/fish_history ~/.config/fish/fish_history
end
