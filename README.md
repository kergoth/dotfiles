# Kergoth's Dotfiles and Setup Scripts

<p align="center">
    <a href="https://spdx.org/licenses/BlueOak-1.0.0.html">
        <img src="https://img.shields.io/badge/License-BlueOak%201.0.0-2D6B79.svg" alt="BlueOak 1.0.0 License" />
    </a>
    <a href="https://deepwiki.com/kergoth/dotfiles">
        <img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki" />
    </a>
</p>

<p align="center">
    <a href="https://www.apple.com/macos/">
        <img src="https://img.shields.io/badge/macOS-000000?logo=macos&logoColor=F0F0F0" alt="macOS" /></a>
    <a href="https://www.microsoft.com/windows/">
        <img src="https://img.shields.io/badge/Windows-0078D6?logo=windows&logoColor=white" alt="Windows" /></a>
    <a href="https://www.debian.org/">
        <img src="https://img.shields.io/badge/Debian-D70A53?logo=debian&logoColor=white" alt="Debian" /></a>
    <a href="https://ubuntu.com/">
        <img src="https://img.shields.io/badge/Ubuntu-E95420?logo=ubuntu&logoColor=white" alt="Ubuntu" /></a>
    <a href="https://fedoraproject.org/">
        <img src="https://img.shields.io/badge/Fedora-294172?logo=fedora&logoColor=white" alt="Fedora" /></a>
    <a href="https://chimera-linux.org/">
        <img src="https://img.shields.io/badge/Chimera%20Linux-FCC624?logo=linux&logoColor=black" alt="Chimera Linux" /></a>
    <a href="https://www.freebsd.org/">
        <img src="https://img.shields.io/badge/-FreeBSD-%23870000?logo=freebsd&logoColor=white" alt="FreeBSD" /></a>
</p>

Personal dotfiles and system setup, managed with [chezmoi](https://www.chezmoi.io/) and [Nix Home Manager](https://nix-community.github.io/home-manager/). This repository covers application configuration, shell customization, package installation, and system-level setup across macOS, Linux, FreeBSD, and Windows.

This is not intended as a starter template. Adopting it wholesale would likely be more complex than most people need.

## Tour

Walk through the daily environment this repository builds. Not every tool is covered here. See the
[Inventory](docs/inventory.md) for the complete list of installed software, plugins, fonts, and system
components.

- **Font:** [MesloLGS NF](https://github.com/romkatv/powerlevel10k/blob/master/font.md), shared across terminals and editors.
- **Color modes:** Dark and light are first-class operating modes.
- **Dark palette:** [Dracula](https://draculatheme.com).
- **Light palette:** Varies by tool based on theme availability.

See [Theming](docs/theming.md) for the palette and mode-detection details.

### Terminal Workspace

<table><tr>
<td><img src="docs/tour/terminal-workspace-dark.png" alt="Terminal workspace in dark mode: Zsh prompt with Git branch, status, and command duration visible" width="100%"></td>
<td><img src="docs/tour/terminal-workspace-light.png" alt="Terminal workspace in light mode: Zsh prompt with Git branch, status, and command duration visible" width="100%"></td>
</tr></table>

[Kitty](https://sw.kovidgoyal.net/kitty/) is the daily terminal, paired with Zsh and a [Powerlevel10k](https://github.com/romkatv/powerlevel10k) prompt. The prompt shows the working
directory, Git branch and status, active language environments, and the duration of slow commands. [Atuin](https://atuin.sh/)
handles shell command history search.

Near-daily utilities: [zoxide](https://github.com/ajeetdsouza/zoxide), [fd](https://github.com/sharkdp/fd), [ripgrep](https://github.com/BurntSushi/ripgrep), [fzf](https://github.com/junegunn/fzf), [eza](https://eza.rocks/), [bat](https://github.com/sharkdp/bat), [duf](https://github.com/muesli/duf), and [dua](https://github.com/Byron/dua-cli).

At startup, zsh runs a daily dotfiles check. If updates are available, it pulls them and applies the changes.
Vim configuration follows the same pattern weekly. Set `DOTFILES_NO_UPDATE` or `VIM_NO_UPDATE` to disable either
check.

### Editors

[Zed](https://zed.dev/) is the primary graphical project editor.

<table><tr>
<td><img src="docs/tour/zed-dark.png" alt="Zed in dark mode with Dracula theme" width="100%"></td>
<td><img src="docs/tour/zed-light.png" alt="Zed in light mode" width="100%"></td>
</tr></table>

Vim is the terminal-native editor and fallback.

<table><tr>
<td><img src="docs/tour/vim-dark.png" alt="Vim in dark mode with Dracula theme" width="100%"></td>
<td><img src="docs/tour/vim-light.png" alt="Vim in light mode" width="100%"></td>
</tr></table>

### Development

Git is the primary source control tool. The configured pager and diff driver add syntax highlighting
and color to log and diff output.

<table><tr>
<td><img src="docs/tour/git-show-dark.png" alt="git show output in dark mode: colored commit decoration, message, and diff" width="100%"></td>
<td><img src="docs/tour/git-show-light.png" alt="git show output in light mode: commit decoration, message, and diff" width="100%"></td>
</tr></table>

A set of aliases extends daily use:

<table><tr>
<td><img src="docs/tour/git-usage-dark.png" alt="Git aliases in use in dark mode" width="100%"></td>
<td><img src="docs/tour/git-usage-light.png" alt="Git aliases in use in light mode" width="100%"></td>
</tr></table>

- **st**: Short status
- **lg**: Single-line formatted log
- **l**: Like `lg` with a line limit; substantially faster on large repositories such as the kernel
- **last**: Time-bounded log. Examples: `git last day`, `git last week`
- **in**: Remote commits not yet in the local branch
- **out**: Local commits not yet in the remote branch
- **brstat**: Branch status in both directions as `git range-diff` output
- **please**: `push --force-with-lease`, a safer force push
- **au**: Stage modifications to tracked files only
- **amend**: Amend the top commit with staged changes

[Tmux](https://github.com/tmux/tmux) maintains background sessions and multi-pane layouts, though most day-to-day splitting happens
in Kitty, Vim, or Zed.

<table><tr>
<td><img src="docs/tour/tmux-statusline-dark.png" alt="Tmux statusline in dark mode with Dracula theme" width="100%"></td>
<td><img src="docs/tour/tmux-statusline-light.png" alt="Tmux statusline in light mode" width="100%"></td>
</tr></table>

Modern Python tooling from [Astral](https://astral.sh/) is preinstalled across all systems: [uv](https://docs.astral.sh/uv/), [ruff](https://docs.astral.sh/ruff/), and [ty](https://github.com/astral-sh/ty).

[Pi](https://pi.dev/) is the preferred LLM agent harness, chosen for its minimal baseline and extensibility.

<table><tr>
<td><img src="docs/tour/pi-statusline-dark.png" alt="Pi statusline in dark mode" width="100%"></td>
<td><img src="docs/tour/pi-statusline-light.png" alt="Pi statusline in light mode" width="100%"></td>
</tr></table>

### Keyboard Configuration

On macOS systems, [Karabiner-Elements](https://karabiner-elements.pqrs.org) is used to configure the keyboard, with these as the most important complex modifications:

- Caps Lock to Escape on single press, Control on press and hold.
- Control to Caps Lock on single press, 'Hyper Key' on press and hold.
- Toggle caps_lock by pressing left_shift + right_shift at the same time.

## How It Works

[Chezmoi](https://www.chezmoi.io/) renders managed source into `$HOME`, handles encrypted secrets via [age](https://age-encryption.org/), and runs setup scripts as part of the apply process. Home Manager is the preferred user package layer where Nix and nixpkgs fit; [Homebrew](https://brew.sh/), [Scoop](https://scoop.sh/), native packages, Flatpak, language package managers, and pinned external installers fill platform gaps. Machine roles and platform differences are handled through chezmoi templates. See [Repository Architecture](docs/repository-architecture.md), [Authoring Chezmoi Configuration](docs/chezmoi-authoring.md), and [Updating External Content](docs/updating-externals.md) for the details.

## Getting Started

On a machine where git is available, clone the repository and run setup:

```console
git clone https://github.com/kergoth/dotfiles .dotfiles
~/.dotfiles/script/setup-full
```

On a fresh machine without git, the bootstrap script installs prerequisites, clones the repository, and initializes chezmoi:

```console
curl -fsLS https://raw.githubusercontent.com/kergoth/dotfiles/main/script/bootstrap | sh
```

## Setup

The setup scripts form a progression from system preparation to user-level configuration:

- `script/setup-system`: installs system-level packages, Nix, and host prerequisites. Requires a non-root user with sudo or doas access. On macOS, your admin user must have signed into the Mac App Store first. On Windows, run `script/setup-system.ps1` from PowerShell rather than WSL.
- `script/setup`: applies dotfiles and runs user-level setup, including package installation via Home Manager and other configured package managers. Run after `setup-system` if system-level dependencies are needed.
- `script/setup-full`: runs `setup-system` followed by `setup`.
- `script/bootstrap`: installs prerequisites, clones the repository, and initializes chezmoi. The setup scripts above run this automatically when needed.

Lower-level `os-install` and `setup-root` entry points handle raw operating system and distro-specific preparation. See [Operating System Installation](docs/os-installation.md) for those flows.

## Day-to-Day

Edit a dotfile and watch for changes:

```console
chezmoi edit --watch ~/.config/zsh/.zshrc
```

See [Authoring Chezmoi Configuration](docs/chezmoi-authoring.md) for source resolution, template rendering, and safe inspection before applying changes.

Apply changes to the home directory manually after editing files in the repository checkout:

```console
chezmoi apply
```

Run a `git pull` in the dotfiles repository and then run `chezmoi apply` on it:

```console
chezmoi update
```

Review and apply available updates to dotfiles, external files, and software packages:

```console
./script/update
```

See [Updating External Content](docs/updating-externals.md) for the review-first source and lock workflow.

## Supporting Docs

- [Inventory](docs/inventory.md): installed software, included external projects, plugins, fonts, scripts, and system or desktop components.
- [Customization](docs/customization.md): local override files and machine-specific configuration paths.
- [Repository Architecture](docs/repository-architecture.md): setup layers, directory responsibilities, and source-to-rendered flow.
- [Theming](docs/theming.md): dark/light mode behavior and tool-specific palettes.
- [Operating System Installation](docs/os-installation.md): raw-OS, WSL, and distro-specific preparation flows.
- [Updating External Content](docs/updating-externals.md): review-first source, lock, and container-pin updates.
- [Contributor Guide](CONTRIBUTING.md): contribution workflow and contributor reference links.

## Contributing & Support

Questions, comments, feedback, and contributions are welcome. Open an issue to start a discussion.

See [CONTRIBUTING.md](CONTRIBUTING.md) for ways to get started contributing to this project.

Please adhere to this project's [Code of Conduct](CODE_OF_CONDUCT.md) and follow [The Ethical Source Principles](https://ethicalsource.dev/principles/).

## License

Distributed under the terms of the [Blue Oak Model License 1.0.0](LICENSE.md) license.


