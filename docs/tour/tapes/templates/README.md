# Tour tape templates

This directory has two kinds of VHS tape template.

## Settings fragments

Capture tapes source one settings fragment at the top of the file.

- `settings-{dark,light}.tape` configures ordinary terminal captures with a colorful window bar and padding.
- `settings-vim-padded-{dark,light}.tape` uses a palette matching Vim's colorscheme background so a fullscreen Vim session blends into the padding. It retains terminal chrome and padding.
- `settings-tui-borderless-{dark,light}.tape` removes the window bar, padding, margin, and border radius for edge-to-edge fullscreen TUI captures.

## Capture recipes

`fullscreen-tui-*`, `no-prompt-*`, `preceding-prompt-*`, and
`preceding-and-following-prompt-*` are copy-and-edit recipes for new captures.
They are not sourced by the existing capture tapes. Replace each placeholder
before running one.

VHS permits one `Source` level and rejects nested sources. Keep a recipe's
settings source directly in that recipe rather than trying to compose a common
settings file, a theme fragment, and a recipe.
