fpath=($ZSH/functions $fpath)

# Mac OS X uses path_helper and /etc/paths.d to preload PATH, clear it out first
if [[ -x /usr/libexec/path_helper ]]; then
    path=()
    eval $(/usr/libexec/path_helper -s)
fi
path=(
  $HOME/bin
  $XDG_DATA_HOME/../bin(N:A)
  $DOTFILESDIR/scripts(:A)
  $DOTFILESDIR/*/scripts(N:A)
  /Users/Shared/homebrew/bin
  /opt/homebrew/bin
  /usr/local/{bin,sbin}
  $path
  /usr/bin/core_perl
)

if [[ -n $commands[manpath] ]]; then
  MANPATH=$(manpath)
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
        /Users/Shared/homebrew/opt/ccache/libexec
        $path
    )
fi

path=( ${(u)^path:A}(N-/) )

# add plugins & topic directories to fpath
fpath=($ZSH/plugins/completions/src $ZSH/plugins/*/(N) $DOTFILESDIR/*/functions(N) $XDG_DATA_HOME/homebrews/*/share/zsh/site-functions(N) /Users/Shared/homebrew/share/zsh/site-functions /Users/Shared/homebrew/opt/*/share/zsh/site-functions(N) $fpath)
