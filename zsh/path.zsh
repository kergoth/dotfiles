fpath=($ZSH/functions $fpath)

path=(
  $HOME/bin
  $ZDG_DATA_HOME/../bin(:A)
  $HOME/.gem/ruby/*/bin(N)
  $HOME/.cabal/bin
  $DOTFILESDIR/scripts(:A)
  /opt/homebrew/bin
  /opt/homebrew/share/python
  /opt/homebrew/share/pypy
  /opt/homebrew/share/pypy3
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
