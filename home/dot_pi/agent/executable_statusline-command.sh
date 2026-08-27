#!/usr/bin/env bash
# PI statusline wrapper around the chezmoi-managed Claude Code statusline.

set -euo pipefail

main() {
    case "${PI_STATUSLINE_THEME:-}" in
        light)
            CLITHEME=light
            ;;
        dracula)
            CLITHEME=dark
            ;;
        *)
            CLITHEME=dark
            ;;
    esac

    export CLITHEME
    bash "$HOME/.dotfiles/home/dot_claude/statusline-command.sh" "$@" | sed 's/CC·/PI·/'
}

main "$@"
