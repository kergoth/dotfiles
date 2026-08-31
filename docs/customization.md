# Customization

This guide covers local changes that are meant to stay outside the shared
dotfiles source. Use these paths for machine-specific settings, private local
preferences, or tool-managed state that should not become part of the
repository.

Chezmoi still owns the managed source. For repository edits, template
variables, run scripts, and rendering checks, use
[Authoring Chezmoi Configuration](chezmoi-authoring.md).

## Shell

- `~/.zshenv.local`: sourced at the end of `.zshenv`. Use it for early
  environment variable overrides that must be visible to all shell types.
- `~/.zprofile.local`: sourced at the end of `.zprofile`. Use it for
  login-shell-specific overrides such as PATH changes that only apply to login
  shells.
- `~/.envrc.local`: sourced from the managed `~/.envrc`. Use it for
  machine-specific session variables or PATH additions that should participate
  in direnv without editing shared dotfiles.
- `~/.zshrc.local` or `~/.localrc`: sourced at the end of `.zshrc`. Use
  either file for interactive shell customizations such as aliases, functions,
  or prompt tweaks.
- `~/.config/zsh/.zshrc.d/*.zsh`: unmanaged files in this directory are
  loaded in glob order alongside managed files. `path.zsh`, `early.zsh`,
  `completion.zsh`, and `final.zsh` have special ordering in the managed
  loader.

## Git

- `~/.gitconfig.local`: included by the main Git config. Use it for
  per-machine settings such as `user.email`, `user.signingkey`, credential
  helpers, or work-specific overrides.

The managed Git entry point is `~/.config/git/config`, a small writable wrapper
that includes the managed main config rather than being the main config itself.
Git-based tools often run `git config --global` to add machine-specific
settings, such as credential manager paths. The wrapper lets those tool-managed
settings stay local without modifying the managed Git config source.

## Tmux

- `~/.tmux.conf.local`: sourced at the end of the tmux configuration if the
  file exists. Use it for per-machine tmux overrides such as key bindings,
  status bar customization, or display settings.

## SSH

- `~/.ssh/config.d/*`: included by the managed SSH config. Use files in this
  directory for per-machine host definitions, jump host settings, or other SSH
  configuration.

## Nix and Home Manager

- `~/.config/home-manager/local.nix`: imported by `home.nix` if the file
  exists. Use it to install additional Nix packages, enable or disable Home
  Manager programs, or override settings from the main configuration.

## Homebrew on macOS

- `scripts/macos/Brewfile.d/*`: processed as additional Brewfile content
  during `chezmoi apply`. Use these files to extend the Homebrew package list
  with machine-specific formulae or casks.
- `scripts/macos/Brewfile-admin.d/*`: processed as additional admin Brewfile
  content during `setup-system`. Use these files for packages requiring the
  shared admin Homebrew prefix.

## Desktop Session Environment

- `~/.session-env.local`: sourced by the included `session-env` integration.

Use this only for non-secret machine-local variables that should be visible to
both GUI applications and command-line tools, such as PATH additions. Do not
put credentials here. Variables injected into a GUI session are broadly visible
to desktop applications; use project-local `.envrc`, tool-specific login flows,
or the platform keychain for secrets.

## Partially Managed Files

Some targets are managed through chezmoi `modify_` templates or scripts. Those
files can contain local edits outside the managed subset, and those local edits
are not visible through normal dotfiles review commands.

`~/bin/chezmoi-diff-managed` can help review these files. Unlike
`chezmoi diff`, it compares destination files with their managed baselines
while rendering `modify_` sources without using the current destination as
input.

When changing a partially managed file, inspect both the rendered managed
operation and the live file before deciding whether a local change belongs in
the repository. Add exact partially managed paths to this section as they are
audited.
