#!/bin/zsh
typeset -TUx GOPATH gopath
gopath=($XDG_DATA_HOME/go $gopath)
path=($path ${GOROOT:-$HOMEBREW_PREFIX/opt/go/libexec}/bin)
for gp in "${gopath[@]}"; do
    path=($gp/bin $path)
done
export GO15VENDOREXPERIMENT=1
