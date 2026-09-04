# Theming

This repository uses a dark or light *mode* and a tool-specific *theme*.

A *palette* is a named set of colors (Dracula, Catppuccin Latte, Alabaster).
A *theme* is a palette applied to a specific tool: the palette plus decisions
about how its colors map to the tool's visual elements (syntax scopes, UI
chrome, decoration styles, background vs. foreground highlighting). The same
palette can produce different themes for the same tool (Alabaster vs. Alabaster
BG both use the Alabaster palette but map it differently). A theme that doesn't
fit can be customized or replaced while keeping its underlying palette.

Dark mode generally uses Dracula. Light mode varies when a tool's available
themes or color handling call for a different choice. The table
below is the current configuration reference. Consult it when changing themes.

## Mode Detection

Kitty, Ghostty, and Zed follow the operating system appearance setting and
select light or dark themes through their own configuration. Each rendering
host detects mode and passes it down to whatever it embeds.

bat and Pi query the terminal background directly via OSC 11 at startup. No
wrapper is needed. bat's `--theme=auto` option pairs `--theme-light` and
`--theme-dark` selections and switches between them based on the OSC 11
response. Pi's `light/dracula` theme setting works the same way.

tmux queries the attached client terminal through OSC 11 when it sources its
configuration, unless `CLITHEME` already gives a dark or light mode. tmux 3.5
and newer also source the matching theme file from the `client-dark-theme`
and `client-light-theme` hooks when the client reports a mode change.

A terminal child process cannot always query OSC 11 because its standard input
and output may be redirected, or the embedding host may start it without access
to the controlling terminal. Statusline subprocesses are one common example. Shell
wrappers therefore resolve `CLITHEME` as `dark` or `light` before starting
tools that need it.

`CLITHEME` is a mode signal, not a palette name. For background, see
[ADR 0005: Use CLITHEME for terminal dark/light mode communication](decisions/0005-clitheme-env-var-for-dark-light-detection.md).
The ADR covers its values and the OSC 11 fallback used when a wrapper has
terminal access. It does not configure graphical applications and is not a
general-purpose replacement for each tool's theme setting.

## Current Theme Map

| Area | Source | Selection mechanism | Dark theme | Light theme |
| --- | --- | --- | --- | --- |
| Kitty | `home/dot_config/kitty/{dark,light}-theme.auto.conf` | Kitty automatic theme includes | Dracula | Alabaster |
| Zed | `settings/zed/settings.json.tmpl` | Zed system mode | Dracula Solid | Alabaster BG High Contrast |
| | | | | |
| vim / nvim | `~/.config/vim/vimrc` (kergoth/dotvim, out of band) | `CLITHEME` env var at startup; falls back to OSC 11 terminal query when absent (vim via `t_RB`; nvim via TUI detection before vimrc) | Dracula | Alabaster (`alabaster-bg`) |
| bat | `home/dot_config/bat/config` | `--theme=auto` with OSC 11 | Dracula | OneHalfLight |
| rg through delta | `home/dot_config/zsh/functions/rg` | `set_clitheme` before invoking delta | Dracula | Catppuccin Latte |
| Pi statusline | `home/dot_pi/agent/extensions/statusline/{index.ts,statusline-format.js}` | Pi UI theme name | Dracula | Catppuccin Latte |
| Pi UI | `settings/pi/settings.json.tmpl` | `light/dracula` appearance pair with OSC 11 | Dracula | Pi light theme |
| | | | | |
| Claude Code statusline | `home/dot_claude/statusline-command.sh` | `CLITHEME`, then OSC 11 fallback | Dracula | Catppuccin Latte |
| Cursor statusline | `home/dot_cursor/executable_statusline.sh` | `CLITHEME`, then OSC 11 fallback | Dracula | Catppuccin Latte |
| gh-dash | `home/dot_config/zsh/functions/gh.tmpl` and `home/dot_config/gh-dash/config-*.yml.tmpl` | `CLITHEME` selects one generated config | Dracula | Catppuccin Latte |
| Glow and Glamour output | `home/dot_config/zsh/functions/set_glamourstyle` | `CLITHEME` sets `GLAMOUR_STYLE` | Dracula | Catppuccin Latte |
| | | | | |
| Git porcelain | `home/dot_config/git/config.main.tmpl` | Git palette-aware color names | Terminal-defined | Terminal-defined |
| tmux | `home/dot_config/tmux/{config,theme-{dark,light}.conf,tmuxline-{dark,light}.conf}` | `CLITHEME`, OSC 11, and tmux 3.5 client mode hooks | tmuxline Dracula-style 256-color palette | Committed light tmuxline palette |
| Windows Terminal | `home/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json` | Fixed profile default | Dracula | None |
| Zsh and PowerShell fzf | `home/dot_config/zsh/dot_zshrc.d/fzf.zsh` and `settings/powershell/profile.ps1` | Fixed `FZF_DEFAULT_OPTS` colors | Dracula | None |

The repository also has a fixed Dracula default for Kitty when no appearance
preference is available (`home/dot_config/kitty/no-preference.auto.conf`) and
for Glow's standalone configuration (`home/dot_config/private_glow/glow.yml`).
For commands the shell wrapper launches, `GLAMOUR_STYLE` takes precedence over
that standalone file.

## Agent Statuslines

Claude Code and Cursor receive `CLITHEME` from the `claude` and `agent` Zsh
wrappers. Their statusline scripts use it first, query OSC 11 only when needed,
and otherwise fall back to dark mode. The dark and light color values for these two
tools are currently duplicated across their scripts. Keep them in sync when
changing either.

Pi does not consume `CLITHEME`. Its statusline extension inspects the active Pi
UI theme directly: `index.ts` selects a palette from `ctx.ui.theme?.name`,
keeping the rendered footer aligned with Pi's current mode.
`statusline-format.js` duplicates the Claude statusline palette by design. Its
comment marks the required alignment.

## Changing a Theme

When changing a dark or light theme:

1. Decide whether the change affects a mode, one tool's theme, or both.
2. Update each row in the theme map that intentionally uses the same palette. Do
   not assume similarly named themes have compatible colors or coverage.
3. Change the Claude, Cursor, and Pi statusline themes together when their
   visual alignment remains intended. Run the focused statusline tests from
   [Testing and Verification](testing.md), including
   `./script/test -j test/node/pi-statusline.test.mjs` for Pi.
4. Check dark and light rendering in the affected graphical application and
   terminal. For `CLITHEME` consumers, test an explicit `CLITHEME=dark` and
   `CLITHEME=light` invocation as well as automatic detection when applicable.
   For tmux, check both initial server startup and a client mode change on tmux
   3.5 or newer.

A future chezmoi data model may share palette values across templates. It should
not hide the fact that tools learn mode in different ways: graphical
applications, terminal wrappers, and Pi extensions each use separate signals.
Add shared variables only when repeated palette values are clear and the shared
model keeps those boundaries visible.

Shared palette hex values can reduce duplication for UI chrome colors (statusline
backgrounds, border accents) where the mapping is straightforward. Per-tool
theme mappings, which palette color maps to which tool element, are judgment
calls that differ by tool and by taste. Upstream theme ports (Catppuccin's 200+
ports, Dracula's ecosystem) already encode those decisions. Reimplementing them
locally as templated data files is only worthwhile when you disagree with enough
of an upstream theme's mapping choices to justify the ongoing maintenance.
