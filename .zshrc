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
