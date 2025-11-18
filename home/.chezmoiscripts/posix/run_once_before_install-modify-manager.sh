#!/bin/sh

HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$HOME/.brew}"
PATH="$HOMEBREW_PREFIX/bin:$HOME/.local/bin:$HOME/bin:$PATH"

if command -v chezmoi_modify_manager >/dev/null 2>&1; then
    exit
fi

tmpdir=$(mktemp -d -t install-package-manager.XXXXXX)
trap 'rm -rf "$tmpdir"' EXIT INT TERM


modify_version=3.5.3
arch=$(uname -m)
case "$arch" in
    arm64)
        arch=aarch64
        ;;
esac
case "$(uname -s)" in
Darwin)
    os=apple-darwin
    ;;
Linux)
    os=unknown-linux-gnu
    ;;
*)
    echo "Error: unsupported OS: $(uname -s)"
    exit 1
    ;;
esac

url="https://github.com/VorpalBlade/chezmoi_modify_manager/releases/download/v${modify_version}/chezmoi_modify_manager-v${modify_version}-${arch}-${os}.tar.gz"

mkdir -p "$HOME/.local/bin"
curl -fsSL --connect-timeout 60 "$url" | tar -C "$HOME/.local/bin" -xz chezmoi_modify_manager
