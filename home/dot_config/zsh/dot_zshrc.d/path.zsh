fpath=($ZDOTDIR/functions $fpath)

path=(
  $HOME/bin
  $XDG_DATA_HOME/../bin(N:A)
  $HOME/.nix/shims
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

if [[ -n $CARGO_HOME ]]; then
    path=($CARGO_HOME/bin $path)
fi

# FreeBSD
path=($path /usr/local/llvm*/bin(N))

if [[ $OSTYPE =~ darwin ]]; then
    path=(
        $HOME/Library/Perl/*/bin(N)
        $HOME/Library/Python/*/bin(N)
        $HOMEBREW_PREFIX/opt/ccache/libexec
        $path
        /System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources
    )
fi

if [[ $OSTYPE = WSL ]]; then
    path=(${0:h:A}/scripts-wsl $path)

    # %PATH% isn't necessarily set when we ssh in
    path=($WslDisks/c/Windows $WslDisks/c/Windows/SysWOW64 $WslDisks/c/Windows/System32 $path)

    # adb
    path=($WslDisks/c/Android/android-sdk/platform-tools $path)
fi

typeset -gxT PYTHONPATH pythonpath
path=($POETRY_HOME/bin $path)

# Nix
if [ -d ~/.nix ]; then
    home_nix=1
else
    home_nix=
fi

for f in etc/profile.d/nix-daemon.sh etc/profile.d/nix.sh etc/profile.d/hm-session-vars.sh; do
    for profile_dir in ~/.nix-profile ~/.nix/var/nix/profiles/per-user/$USER/profile \
                       /nix/var/nix/profiles/per-user/$USER/profile \
                       /nix/var/nix/profiles/default; do
        if [ -e "$profile_dir/$f" ]; then
            . "$profile_dir/$f"
            break
        fi
    done
done

if [[ -e ~/.nix-profile ]]; then
    manpath=(~/.nix-profile/share/man $manpath)
    fpath=(~/.nix-profile/share/zsh/site-functions $fpath)
    path=(~/.nix-profile/bin $path)
    xdg_data_dirs=(~/.nix-profile/share $xdg_data_dirs)
fi

if [[ -n $buildInputs ]]; then
    for p in $=buildInputs; do
        manpath=($p/share/man $manpath)
        fpath=($p/share/zsh/site-functions $fpath)
        path=($p/bin $path)
        xdg_data_dirs=($p/share $xdg_data_dirs)
    done
fi

path=( ${(u)^path:A}(N-/) )

# add plugins & topic directories to fpath
fpath=($ZDOTDIR/plugins/completions/src $ZDOTDIR/plugins/*/(N) $ZDOTDIR/functions $XDG_DATA_HOME/zsh/functions $XDG_CACHE_HOME/zsh/functions $XDG_CACHE_HOME/zsh/completions $XDG_DATA_HOME/zsh/completions $XDG_CONFIG_HOME/*/zsh-functions(N) $XDG_CACHE_HOME/zsh/completions $XDG_DATA_HOME/homebrews/*/share/zsh/site-functions(N) $HOMEBREW_PREFIX/share/zsh/site-functions $HOMEBREWS_HOME/*/share/zsh/site-functions(N) $HOMEBREW_PREFIX/opt/*/share/zsh/site-functions(N) $fpath)
