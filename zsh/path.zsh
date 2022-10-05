fpath=($ZSH/functions $fpath)

path=(
  $HOME/bin
  $XDG_DATA_HOME/../bin(N:A)
  $DOTFILESDIR/scripts(:A)
  $DOTFILESDIR/*/scripts(N:A)
  $HOMEBREW_PREFIX/bin
  $HOMEBREW_PREFIX/sbin
  /opt/homebrew/bin
  /usr/local/{bin,sbin}
  $path
  /usr/bin/core_perl
)
if [[ -n $commands[manpath] ]]; then
  MANPATH=$(MANPATH= manpath)
else
  MANPATH=/usr/local/man:/usr/local/share/man:/usr/man:/usr/share/man
fi
manpath=($XDG_DATA_HOME/man $manpath)

if [[ -n $GOPATH ]]; then
    path=($GOPATH/bin $path)
fi

if [[ $OSTYPE =~ darwin ]]; then
    path=(
        $HOME/Library/Perl/*/bin(N)
        $HOME/Library/Python/*/bin(N)
        $HOMEBREW_PREFIX/opt/ccache/libexec
        $path
    )
fi

path=( ${(u)^path:A}(N-/) )

# add plugins & topic directories to fpath
fpath=($ZSH/plugins/completions/src $ZSH/plugins/*/(N) $DOTFILESDIR/*/zsh-functions(N) $ZSH/functions $XDG_CACHE_HOME/zsh/completions $XDG_DATA_HOME/homebrews/*/share/zsh/site-functions(N) $HOMEBREW_PREFIX/share/zsh/site-functions $HOMEBREWS_HOME/*/share/zsh/site-functions(N) $HOMEBREW_PREFIX/opt/*/share/zsh/site-functions(N) $fpath)
