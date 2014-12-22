#!/bin/zsh
typeset -TUx GOPATH gopath
gopath=($XDG_DATA_HOME/go $gopath)
for gp in "${gopath[@]}"; do
    path=($gp/bin $path)
done
