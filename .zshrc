if [[ -z $TMUX ]]; then
        if which tmux >/dev/null 2>&1; then
                # Our tmux configuration spawns a default session, so we can
                # create a unique session linked to it here.
                ~/bin/tmux_link default newwindow && exit 0
        fi
fi

autoload -U compinit zrecompile

. ~/.zsh/volatile

mkdir -p $zsh_cache

zstyle :compinstall filename ~/.zshrc
if [ $UID -eq 0 ]; then
        compinit
else
        compinit -d $zsh_cache/zcomp-$HOST

        for f in ~/.zshrc $zsh_cache/zcomp-$HOST; do
                zrecompile -p $f && rm -f $f.zwc.old
        done
fi

setopt extended_glob
for zshrc_snipplet in ~/.zsh/conf.d/S[0-9][0-9]*[^~] ; do
        source $zshrc_snipplet
done
