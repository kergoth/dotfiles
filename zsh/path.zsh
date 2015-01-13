fpath=($ZSH/functions $fpath)

# Mac OS X uses path_helper and /etc/paths.d to preload PATH, clear it out first
if [[ -x /usr/libexec/path_helper ]]; then
    path=()
    eval $(/usr/libexec/path_helper -s)
fi
path=(
  $HOME/bin
  $XDG_DATA_HOME/../bin(N:A)
  $HOME/.gem/ruby/*/bin(N)
  $HOME/.cabal/bin
  $DOTFILESDIR/scripts(:A)
  /opt/homebrew/bin
  /usr/local/{bin,sbin}
  $path
  /usr/bin/core_perl
)

if [[ -n $GOPATH ]]; then
    path=($GOPATH/bin $path)
fi

if [[ $OSTYPE =~ darwin ]]; then
    path=(
        $HOME/Library/Perl/*/bin(N)
        $HOME/Library/Python/*/bin(N)
        $path
    )
fi

# add plugins & topic directories to fpath
fpath=($ZSH/plugins/zsh-completions/src $ZSH/plugins/*/(N) $DOTFILESDIR/*/(N) $fpath)
