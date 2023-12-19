#!/bin/sh

HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$HOME/.brew}"
PATH="$HOMEBREW_PREFIX/bin:$HOME/.local/bin:$PATH"

if command -v op >/dev/null 2>&1; then
    exit
fi
if ! grep -E '^ *is_(home|siemens) *= *true' ~/.config/chezmoi/chezmoi.toml; then
    exit
fi

tmpdir=$(mktemp -d -t install-package-manager.XXXXXX)
trap 'rm -rf "$tmpdir"' EXIT INT TERM

case "$(uname -s)" in
Darwin)
    if ! [ -x "$HOMEBREW_PREFIX/bin/brew" ]; then
        echo >&2 "Installing homebrew"
        "$CHEZMOI_COMMAND_DIR/scripts/macos/install-brew" -s "$HOMEBREW_PREFIX" || {
            rm -rf "$HOMEBREW_PREFIX"
            echo >&2 "Failed to install homebrew"
            exit 1
        }
    fi

    if command -v brew >/dev/null 2>&1; then
        brew install 1password-cli
    fi
    ;;
Linux)
    case "$(uname -m)" in
    x86_64)
        ARCH=amd64
        ;;
    aarch64)
        ARCH=arm64
        ;;
    *)
        echo >&2 "Error: unsupported arch from uname -m: $(uname -m)"
        exit 1
        ;;
    esac
    if wget "https://cache.agilebits.com/dist/1P/op2/pkg/v2.24.0/op_linux_${ARCH}_v2.24.0.zip" -O "$tmpdir/op.zip"; then
        mkdir -p ~/.local/bin
        if command -v unzip >/dev/null 2>&1; then
            unzip -d ~/.local/bin "$tmpdir/op.zip" op
        elif command -v unar >/dev/null 2>&1; then
            unar -f -D -o ~/.local/bin "$tmpdir/op.zip" op
        else
            echo >&2 "Error: no supported unzip tool installed"
            exit 1
        fi
    else
        exit 1
    fi
    chmod +x ~/.local/bin/op
    ;;
*)
    echo "Error: unsupported OS: $(uname -s)"
    exit 1
    ;;
esac
