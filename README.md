# Kergoth's Dotfiles and Setup Scripts

<p align="center">
    <a href="https://spdx.org/licenses/BlueOak-1.0.0.html">
        <img src="https://img.shields.io/badge/License-BlueOak%201.0.0-2D6B79.svg" alt="BlueOak 1.0.0 License" />
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

Personal dotfiles and system setup, managed with [chezmoi] and [Nix Home Manager][home-manager]. This repository covers application configuration, shell customization, package installation, and system-level setup across macOS, Linux, FreeBSD, and Windows. All machine-specific differences and optional feature flags are handled through chezmoi's template system.

## How It Works

[Chezmoi][chezmoi] manages dotfiles: it templates configuration files, applies them to `$HOME`, handles encrypted secrets via [age], and runs setup scripts as part of the apply process. [Nix Home Manager][home-manager] provides the primary method of declarative, reproducible package management at the user level where Nix and nixpkgs are viable, supplemented by [Homebrew] on macOS, [Scoop] on Windows, and language-specific package managers as needed. Where that path is unavailable or incomplete, the setup falls back to system package managers and other installation methods. See [Platform Notes](#platform-notes) for FreeBSD and Chimera Linux.

Chezmoi templates drive per-machine configuration. Flags in `~/.config/chezmoi/chezmoi.toml` control what gets installed and configured: for example, whether the machine is a work system, has a container runtime, or is headless. Sensitive files are encrypted with age, with the key bootstrapped from 1Password on first setup if not placed manually.

**A note on scope:** This is not intended as a starter template, as adopting it wholesale would likely be more complex than most people need.

### Setup Entry Points

The setup scripts form a progression from OS installation to day-to-day dotfiles application:

- **OS installation** (distro-specific, self-contained):
  - **`os-install`**: Installs the OS from a live environment. Available for Arch and Chimera Linux.
  - **`setup-root`**: Runs as root to create users, install base packages, and prepare for user-level setup. Available for a subset of platforms.
- **`bootstrap`**: Installs prerequisites, clones the repository, and initializes chezmoi. Run automatically by the setup scripts below.
- **`setup-system`**: Installs system-level packages, Nix, and other prerequisites. Run by a non-root user with sudo/doas access.
- **`setup`** / `chezmoi apply`: Applies dotfiles and runs chezmoi scripts for user-level package installation, application configuration, and shell setup.
- **`setup-full`**: Runs `setup-system` then `setup`.

## Usage

### Bootstrap (Optional)

The setup scripts below handle bootstrapping automatically. If you prefer to initialize chezmoi separately — or need to run on a system where the repository isn't yet cloned and git isn't yet available — you can run `script/bootstrap` standalone:

```console
curl -fsLS https://raw.githubusercontent.com/kergoth/dotfiles/main/script/bootstrap | sh
```

This installs prerequisites (git, bash, curl, unzip), clones the repository if needed, and installs and initializes chezmoi.

### Full Setup

Clone the repository and run `setup-full` for both system-level setup and dotfiles on a fresh machine:

```console
git clone https://github.com/kergoth/dotfiles .dotfiles
~/.dotfiles/script/setup-full
```

### System Setup

**Run this before dotfiles setup** if you need system-level packages, Nix, or other prerequisites. This script is run by a non-root user with sudo/doas access. To complete this on macOS, your admin user must have signed into the Mac App Store.

```console
./script/setup-system
```

On Windows (in PowerShell, not WSL):

```console
./script/setup-system.ps1
```

### Dotfiles Setup

Applies dotfiles and runs chezmoi scripts for user-level package installation and configuration. **If system setup is needed, run `setup-system` first** — dotfiles application may depend on tools it installs (e.g. Nix).

If the repository has not yet been cloned:

```console
chezmoi init kergoth/dotfiles
~/.dotfiles/script/setup
```

If the repository is already cloned:

```console
./script/setup
```

### Edit dotfiles

```console
chezmoi edit --watch ~/.config/zsh/.zshrc
```

### Apply dotfiles changes to the home directory

This step is implicitly done by the setup script. To run it manually, for example, after editing files inside the repository checkout, run this:

```console
chezmoi apply
```

### Update the dotfiles, external files, and home directory packages

```console
./script/update
```

## Local Configuration

These files are not tracked in the repository and allow per-machine customization without modifying managed dotfiles.

### Shell (Zsh)

- **`~/.zshenv.local`** — Sourced at the end of `.zshenv`. Use for early environment variable overrides that need to be set in all shell types (interactive, non-interactive, login, non-login).
- **`~/.zprofile.local`** — Sourced at the end of `.zprofile`. Use for login-shell-specific overrides such as PATH modifications or environment setup that only applies to login shells.
- **`~/.envrc.local`** — Sourced from the managed `~/.envrc`. Use for machine-specific session variables or PATH additions that should participate in direnv and desktop-session environment injection without editing the shared dotfiles.
- **`~/.zshrc.local`** or **`~/.localrc`** — Sourced at the end of `.zshrc`. Use for interactive shell customizations such as aliases, functions, or prompt tweaks specific to this machine.
- **New `.zsh` files in `~/.config/zsh/.zshrc.d/`** — Any `.zsh` file placed here is automatically sourced by `.zshrc`. Files are loaded in glob order, with special handling for `path.zsh` (loaded first), `early.zsh`, `completion.zsh`, and `final.zsh`. Unmanaged files in this directory coexist with chezmoi-managed ones.

### Git

- **`~/.gitconfig.local`** — Included by the main git config via `[include]`. Use for per-machine settings such as `user.email`, `user.signingkey`, credential helpers, or work-specific overrides.

### Tmux

- **`~/.tmux.conf.local`** — Sourced at the end of the tmux configuration if the file exists. Use for per-machine tmux overrides such as different key bindings, status bar customization, or display settings.

### SSH

- **Files in `~/.ssh/config.d/`** — All files in this directory are included by the SSH config via `Include ~/.ssh/config.d/*`. Use for per-machine host definitions, jump host configurations, or other SSH settings.

### Nix / Home Manager

- **`~/.config/home-manager/local.nix`** — Optionally imported by `home.nix` if the file exists. Use to install additional Nix packages, enable or disable Home Manager programs, or override settings from the main configuration.

### Homebrew (macOS)

- **Files in `scripts/macos/Brewfile.d/`** — Each file in this directory is processed as an additional Brewfile during `chezmoi apply`. Use to extend the Homebrew package list with machine-specific formulae or casks.
- **Files in `scripts/macos/Brewfile-admin.d/`** — Each file is processed as an additional Brewfile during `setup-system`. Use to extend the admin Homebrew package list (for packages requiring the shared admin Homebrew prefix).

### Desktop Session Environment

- `~/.session-env.local` — This file is sourced by the session-env script, which injects its variables into the environment of GUI applications and shell sessions restored via direnv. Use this for machine-local environment variable additions that should be visible to desktop apps and CLI tools alike. Avoid putting secrets here, since it will make them available to every GUI app and CLI tool in the session. For secrets, prefer project-local `.envrc`, app- or tool-specific login flows, or the platform keychain.

### Notes

- `.config/git/config` is not my main configuration, but is instead a small file
  which includes my main configuration. This allows for automatic git
  configuration changes such as vscode's change to credential.manager to be
  obeyed without it altering my stored git configuration. The downside to this
  is that these changes will not be highly visible. I may change this back, or
  keep the including file but track it so the changes are visible.

## What's Included

### Zsh Plugins

- **[fzf-tab](https://github.com/Aloxaf/fzf-tab)**: Replace zsh's default completion selection menu with fzf.
- **[nix-zsh-completions](https://github.com/nix-community/nix-zsh-completions)**: ZSH Completions for Nix.
- **[powerlevel10k](https://github.com/romkatv/powerlevel10k/)**: A Zsh theme.
- **[zbell](https://gist.githubusercontent.com/jpouellet/5278239)**: Make Zsh print a bell when long-running commands finish.
- **[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)**: Fish-like autosuggestions for zsh.
- **[zsh-bd](https://github.com/Tarrasch/zsh-bd)**: Jump back to a specific directory, without doing `cd ../../..`.
- **[zsh-completions](https://github.com/zsh-users/zsh-completions)**: Additional completion definitions for Zsh.
- **[zsh-git-escape-magic](https://github.com/knu/zsh-git-escape-magic)**: zle tweak for git command line arguments.
- **[zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)**: ZSH port of Fish history search (up arrow).
- **[zsh-manydots-magic](https://github.com/knu/zsh-manydots-magic)**: zle tweak for emulating ...==../.. etc.
- **[zsh-nix-shell](https://github.com/chisui/zsh-nix-shell)**: Zsh plugin that lets you use zsh in nix-shell shells.
- **[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)**: Fish shell like syntax highlighting for Zsh.

### Agent Additions

#### Rules

Rules are rendered from repo-managed templates into always-loaded context files for each agent tool: `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and `~/.cursor/rules/agent-rules.mdc`.

#### Skills

Skills live in `~/.agents/skills/` and are available to all agent tools (Claude Code, Codex, Cursor) unless noted otherwise.

##### First-Party

- **[Clean Prose](home/dot_agents/skills/clean-prose/SKILL.md)**: Improve prose quality and reduce AI writing patterns in written artifacts.
- **[Cram](home/dot_agents/skills/cram/SKILL.md)**: Write, read, and debug [cram](https://bitheap.org/cram/) functional tests (.t files).
- **[Find Session](home/dot_agents/skills/find-session/SKILL.md)**: Find and resume past Claude Code conversations by keyword search.
- **[Jujutsu](home/dot_agents/skills/jujutsu/SKILL.md)**: Version control for [Jujutsu (jj)](https://github.com/jj-vcs/jj) repositories.
- **[Obsidian CLI](home/dot_agents/skills/obsidian-cli/SKILL.md)**: Work with the [Obsidian](https://obsidian.md) CLI.
- **[Shell Script Style](home/dot_agents/skills/shell-script-style/SKILL.md)**: Apply personal Bash/POSIX shell script style conventions.

##### External

- **[Anthropic Official Plugins](https://github.com/anthropics/claude-plugins-official/tree/main/plugins)**: Claude Code setup, maintenance, and skill authoring.
  - **[claude-automation-recommender](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-code-setup)**: Analyze codebase and recommend Claude Code automations (hooks, subagents, skills, MCP servers).
  - **[claude-md-improver](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-md-management)**: Audit and improve CLAUDE.md files.
  - **[skill-creator](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/skill-creator)**: Create and refine skills.
- **[Astral](https://github.com/astral-sh/claude-code-plugins/tree/main/plugins/astral/skills)**: Python tooling skills. Also installed as a Claude Code plugin for `ty` LSP integration.
  - **ruff**: Linting and formatting Python code.
  - **ty**: Type checking Python code.
  - **uv**: Managing Python projects, packages, and tools.
- **[avoid-ai-writing](https://github.com/conorbronsdon/avoid-ai-writing)**: Vocabulary and structural pattern detection for reducing AI writing patterns. Used as the base layer for the clean-prose skill.
- **[gh-pr-review](https://github.com/agynio/gh-pr-review)**: GitHub PR review threads and inline review comments with structured terminal workflows.
- **[Readwise Skills](https://github.com/readwiseio/readwise-skills/tree/main/skills)**: Readwise Reader workflows.
  - **build-persona**: Build a reading profile from library history; personalizes quiz and feed-catchup output.
  - **feed-catchup**: Batch-process RSS feeds and newsletters to surface valuable content.
  - **quiz**: Self-assessment on recently read content with grading.
  - **reader-recap**: Conversational briefing on recent reading activity.
- **[Superpowers](https://github.com/obra/superpowers/tree/main/skills)**: Core workflow skills for agentic coding.
  - **brainstorming**: Explore intent, requirements, and design before implementation.
  - **dispatching-parallel-agents**: Coordinate independent tasks across multiple agents.
  - **executing-plans**: Execute written implementation plans with review checkpoints.
  - **finishing-a-development-branch**: Structured options for merging, PRs, or cleanup when work is complete.
  - **receiving-code-review**: Process review feedback with technical rigor, not blind agreement.
  - **requesting-code-review**: Verify work meets requirements before merging.
  - **subagent-driven-development**: Execute implementation plans with independent in-session tasks.
  - **systematic-debugging**: Structured approach to bugs and test failures before proposing fixes.
  - **test-driven-development**: Write tests before implementation code.
  - **using-git-worktrees**: Isolate feature work in git worktrees.
  - **using-superpowers**: Session entry point; establishes skill discovery and invocation discipline.
  - **verification-before-completion**: Require evidence before claiming work is done.
  - **writing-plans**: Plan multi-step tasks before touching code.

#### MCP Servers

- **[Context7](https://github.com/upstash/context7-mcp)**: Fetch up-to-date library documentation and code examples from source repositories. _Claude Code: unconditional. Codex: personal machines. Cursor: work machines._
- **[DeepWiki](https://deepwiki.com)**: Query documentation and knowledge from GitHub repositories. _Claude Code: unconditional. Codex: personal machines. Cursor: work machines._
- **[Readwise](https://docs.readwise.io/readwise/guides/mcp)**: Search and retrieve highlights from Readwise; powers the Readwise Skills. _Conditional: personal machines, not ephemeral._

### Fonts

- **[iA-Fonts](https://github.com/iaolo/iA-Fonts)**: iA Writer Mono, Duo, and Quattro.
- **[MesloLGS NF](https://github.com/romkatv/powerlevel10k/blob/master/font.md)**: Meslo Nerd Font patched for Powerlevel10k.

### Third-Party Scripts

- **git-alias** ([source](https://github.com/tj/git-extras)): Manage git command aliases.
- **[git-attic](https://chneukirchen.org/dotfiles/bin/git-attic)**: List deleted files from git history with their deletion details.
- **git-j** ([source](https://github.com/beanbaginc/dev-goodies)): Jump between git branches with history tracking.
- **git-rebase-chain** ([source](https://github.com/beanbaginc/dev-goodies)): Rebase a stack of branches from one base to another.
- **ifne** ([source](https://github.com/fumiyas/home-commands)): Run a command only if standard input is not empty. This is a third-party script reimplementation of a tool from [moreutils by Joey Hess](https://joeyh.name/code/moreutils/).
- **linux-bundle-clone** ([source](https://git.kernel.org/pub/scm/linux/kernel/git/mricon/korg-helpers.git)): Clone Linux kernel repositories using CDN-hosted bundles.
- **vipe** ([source](https://github.com/madx/moreutils)): Edit pipe content in your text editor mid-pipeline. This is a third-party script reimplementation of a tool from [moreutils by Joey Hess](https://joeyh.name/code/moreutils/).
- **[wsl-open](https://github.com/4U6U57/wsl-open)**: Open files and URLs from WSL in Windows default applications.

## System & Desktop Configuration

- **Desktop environment**: KDE Plasma on Linux and FreeBSD. _Conditional: non-headless._
- **Display manager**: SDDM on Linux and FreeBSD. _Conditional: non-headless. init present to enable/start._
- **Terminal emulator**: kitty on macOS, Linux, and FreeBSD; Windows Terminal on Windows. _Conditional: non-headless._
- **PDF viewer**: Okular on Linux and FreeBSD. _Conditional: non-headless._
- **App distribution (Flatpak)**: Flatpak + Flathub on all supported Linux distros. Primary mechanism for GUI app installs where native packages are absent or stale. _Conditional: non-headless._
- **Core services**: mDNS/Avahi, SSH, Bluetooth, and audio stack. PipeWire where applicable. Varies by distro.
- **Optional system services**: Tailscale, container runtime. _Conditional: personal, non-ephemeral for Tailscale. containers flag for container runtime._
- **OS exceptions/notes**: Service enablement is skipped for WSL2/containers/ephemeral systems.

### Desktop Session Environment

Desktop-launched applications on macOS and Linux do not read shell startup files, so they often miss environment variables that are available in terminal sessions. This setup uses `session-env` to inject a small set of shared variables into the desktop session so GUI apps inherit the same basic context, especially `PATH`.

In this repo, the managed defaults currently provide `PATH` and `EMAIL`.

Terminals launched from the desktop environment inherit those variables automatically, so nothing special is needed there beyond the desktop-session injection itself.

The home-level `~/.envrc` is a `direnv` bridge for shell entry points that bypass the desktop session, especially SSH. In those cases, it sources `~/.session-env` so direnv can recreate the same baseline environment in CLI sessions that did not inherit it from the desktop login.

## Installed Software

Installed software varies by platform based on package availability and platform-specific tools, but the general approach is consistent: use Nix and nixpkgs where possible, with Homebrew on macOS, Scoop on Windows, and native packages or language-specific package managers as fallbacks. For GUI apps on Linux, Flatpak is preferred. On Chimera Linux, where native packaging and flatpak is insufficient, this setup falls back to an Ubuntu distrobox for glibc-only GUI applications. On FreeBSD, for GUI apps without native support, Linuxulator is used to run Linux userspace applications.

### Installed CLI Software

- **[curl](https://curl.se)**: Command line tool and library for transferring data with URLs.
- **[wget](https://www.gnu.org/software/wget/)**: A free software package for retrieving files using HTTP, HTTPS, FTP and FTPS.
- **[gh](https://cli.github.com)**: GitHub’s official command line tool.
  - **[gh-pr-review](https://github.com/agynio/gh-pr-review)**: GitHub CLI extension that adds full inline PR review comment support directly from the terminal.
- **[git](https://git-scm.com)**: A free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.
- **[git-lfs](https://git-lfs.github.com)**: An open source Git extension for versioning large files.
- **[neovim](https://neovim.io)**: Hyperextensible Vim-based text editor.
- **[gnupg](https://www.gnupg.org)**: A complete and free implementation of the OpenPGP standard.

- **[nodejs](https://nodejs.org)** ([Open-Source](https://github.com/nodejs/node)): A JavaScript runtime built on Chrome's V8 JavaScript engine.
- **[python](https://www.python.org)**: A programming language that lets you work quickly and integrate systems more effectively.
- **[uv](https://github.com/astral-sh/uv)**: An extremely fast Python package installer and resolver, written in Rust.

- **[atuin](https://github.com/ellie/atuin)**: ✨ Magical shell history.
- **[bat](https://github.com/sharkdp/bat)**: A cat(1) clone with syntax highlighting and Git integration.
  - **[bat-extras](https://github.com/eth-p/bat-extras)**: Scripts that integrate bat with various command line tools.
- **[choose](https://github.com/theryangeary/choose)**: A human-friendly and fast alternative to cut and (sometimes) awk.
- **[Claude Code](https://code.claude.com)**: Anthropic's agentic coding tool for your terminal.
- **[delta](https://github.com/dandavison/delta)**: A syntax-highlighting pager for git, diff, and grep output.
- **[difftastic](https://github.com/Wilfred/difftastic)** ([Open-Source](https://github.com/Wilfred/difftastic)): A structural diff tool that compares files based on their syntax.
- **[direnv](https://direnv.net)**: An extension for your shell which can load and unload environment variables depending on the current directory.
- **[docker](https://www.docker.com/)** ([Open-Source](https://github.com/moby/moby)): Platform for developing, shipping, and running applications in containers. _Conditional: containers flag._
- **[docker-compose](https://docs.docker.com/compose/)** ([Open-Source](https://github.com/docker/compose)): Define and run multi-container Docker applications. _Conditional: containers flag._
- **[dtrx](https://github.com/dtrx-py/dtrx)**: Intelligent archive extraction tool. Installed as a fallback when unar is unavailable.
- **[duf](https://github.com/muesli/duf)**: Disk Usage/Free Utility - a better 'df' alternative.
- **[dua](https://github.com/Byron/dua-cli)**: View disk space usage and delete unwanted data, fast. This is a faster version of ncdu.
- **[fclones](https://github.com/pkolaczk/fclones)**: Finds and removes duplicate files.
- **[restic](https://restic.net)** ([Open-Source](https://github.com/restic/restic)): Fast, secure, efficient backup program.
- **[rsync](https://rsync.samba.org/)**: Fast, versatile file copying tool for remote and local files.
- **[Tailscale](https://tailscale.com)** ([Open-Source](https://github.com/tailscale/tailscale)): WireGuard-based mesh VPN that makes it easy to connect your devices securely. _Conditional: personal, non-ephemeral._
- **[eza](https://github.com/eza-community/eza)** or [exa](https://github.com/ogham/exa): A modern replacement for ls.
- **[fd](https://github.com/sharkdp/fd)**: A simple, fast and user-friendly alternative to 'find'.
- **[fzf](https://github.com/junegunn/fzf)**: A command-line fuzzy finder.
- **[ghq](https://github.com/x-motemen/ghq)**: Remote repository management made easy.
- **[git-absorb](https://github.com/tummychow/git-absorb)**: git commit --fixup, but automatic.
- **[git-assembler](https://gitlab.com/wavexx/git-assembler)**: Update git branches using high-level assembly instructions.
- **[git-crypt](https://github.com/AGWA/git-crypt)** ([Open-Source](https://github.com/AGWA/git-crypt)): Transparent file encryption in git. _Conditional: work._
- **[git-imerge](https://github.com/mhagger/git-imerge)**: Incremental merge for git.
- **[git-revise](https://github.com/mystor/git-revise)**: A handy tool for doing efficient in-memory commit rebases & fixups.
- **[glow](https://github.com/charmbracelet/glow)**: Renders markdown in the terminal.
- **[google-cloud-sdk](https://cloud.google.com/sdk)**: Tools for the Google Cloud Platform. _Conditional: work._
- **[jira-cli](https://github.com/ankitpokhrel/jira-cli)** (_Only on Work machines_): Feature-rich interactive Jira command line.
- **[jujutsu](https://github.com/jj-vcs/jj)** ([Open-Source](https://github.com/jj-vcs/jj)): Git-compatible VCS that is both simple and powerful.
- **[jq](https://github.com/stedolan/jq)**: A lightweight and flexible command-line JSON processor.
- **[ripgrep](https://github.com/BurntSushi/ripgrep)**: A line-oriented search tool that recursively searches the current directory for a regex pattern.
- **[rusage.com](https://justine.lol/rusage/)**: Provides the best possible way to report resource usage statistics when launching command line programs.
- **[sad](https://github.com/ms-jpq/sad)**: CLI search and replace | Space Age seD.
- **[sd](https://github.com/chmln/sd)**: Intuitive find & replace CLI (sed alternative).
- **[shellcheck](https://github.com/koalaman/shellcheck)**: A static analysis tool for shell scripts.
- **[shfmt](https://github.com/mvdan/sh#shfmt)**: Format shell programs.
- **[tealdeer](https://github.com/dbrgn/tealdeer)**: Simplified, example based and community-driven man pages.
- **[uv](https://docs.astral.sh/uv/)** ([Open-Source](https://github.com/astral-sh/uv)): An extremely fast Python package and project manager, written in Rust.
- **[zoxide](https://github.com/ajeetdsouza/zoxide)**: A smarter cd command, inspired by z and autojump.
- **[zstd](http://www.zstd.net/)**: Zstandard - Fast real-time compression algorithm.

#### CLI Software on Linux and macOS

- **[Codex](https://github.com/openai/codex)**: OpenAI's agentic coding tool for your terminal.
- **[nix](https://nixos.org)**: Nix is a tool that takes a unique approach to package management and system configuration.

#### CLI Software on Linux, macOS, and FreeBSD

- **[patchutils](http://cyberelk.net/tim/software/patchutils/)**: A small collection of programs that operate on patch files.
  - On Windows, patchutils can be used via either WSL or MSYS2 (which can be installed via scoop and run as `msys2`, ex. `msys2 -c 'exec filterdiff "$@"' -`).

- **[ssh-copy-id](https://www.openssh.com)**: Install your identity.pub in a remote machine’s authorized_keys.
  - On Windows, I have a powershell function which does this, and is aliased to `ssh-copy-id`.

- **[tmux](https://github.com/tmux/tmux)**: An open-source terminal multiplexer.
  - There are no good options for tmux or tmux-equivalent on Windows. The closest you can get is just splits in Windows Terminal, which doesn't give you the ability to disconnect.

#### CLI Software on Linux (non-Chimera), macOS, FreeBSD, and Windows

- **[unar](https://theunarchiver.com/command-line)**: Universal archives extractor. Available via brew, nix, and scoop.

#### CLI Software on FreeBSD

- **[go](https://go.dev)**: An open source programming language supported by Google
  - Installed so we can `go install` various tools.

- **[podman](https://podman.io)**: A daemonless container engine for developing, managing, and running OCI Containers. _Conditional: containers flag._
- **[podman-compose](https://github.com/containers/podman-compose)**: A script to run docker-compose.yml using podman. _Conditional: containers flag._

- **[rust](https://www.rust-lang.org)**: A multi-paradigm, general-purpose programming language.
  - Installed so we can `cargo install` various tools.

#### CLI Software on macOS

- **[lima](https://github.com/lima-vm/lima)**: Linux virtual machines, typically on macOS, for running containerd.
- **[colima](https://github.com/abiosoft/colima)**: Container runtimes on macOS (and Linux) with minimal setup. _Conditional: This is installed when a container runtime is enabled._
- **[duti](https://github.com/moretension/duti)**: A command-line tool to select default applications for document types and URL schemes on Mac OS X.
- **[mas](https://github.com/mas-cli/mas)**: Mac App Store command line interface.
- **[reattach-to-user-namespace](https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard)**: Reattach to the per-user bootstrap namespace. This is needed for tools like tmux, though tmux 2.6+ apparently incorporates this functionality already.
- **[trash](https://hasseg.org/trash/)**: A small command-line program for OS X that moves files or folders to the trash.

#### CLI Software on Linux and FreeBSD

- **[zsh](https://zsh.sourceforge.io)**: A shell designed for interactive use, although it is also a powerful scripting language. This is installed by default on macOS.

#### CLI Software on Linux

- **[distrobox](https://distrobox.it/)** ([Open-Source](https://github.com/89luca89/distrobox)): Use any Linux distribution inside your terminal.

##### CLI Software on Arch Linux

- **[openssh](https://www.openssh.com)**: The premier connectivity tool for remote login with the SSH protocol.
- **[avahi](https://avahi.org)**: A system which facilitates service discovery on a local network via mDNS.
- **[nss-mdns](http://0pointer.de/lennart/projects/nss-mdns/)**: A GNU Libc NSS module that provides mDNS host name resolution.

##### CLI Software on WSL2

- **[npiperelay](https://github.com/jstarks/npiperelay)**: Access Windows named pipes from WSL.
- **[socat](http://www.dest-unreach.org/socat/)**: Multipurpose relay for bidirectional data transfer. This is required for [npiperelay](https://github.com/jstarks/npiperelay).

##### CLI Software on Chimera Linux

- **[podman](https://podman.io)**: A daemonless container engine for developing, managing, and running OCI Containers. _Conditional: containers flag._
- **[podman-compose](https://github.com/containers/podman-compose)**: A script to run docker-compose.yml using podman. _Conditional: containers flag._
  - Note: Chimera Linux and FreeBSD use podman instead of docker due to potential compatibility issues with docker on their BSD userland.

#### CLI Software on Windows

- **[gow](https://github.com/bmatzelle/gow)**: Unix command line utilities installer for Windows.
- **[gsudo](https://github.com/gerardog/gsudo)**: Sudo for Windows.
- [PowerShell](https://learn.microsoft.com/en-us/powershell/) ([Open-Source](https://github.com/PowerShell/PowerShell))
- **[recycle-bin](https://github.com/sindresorhus/recycle-bin)**: Move files and folders to the Windows recycle bin within command line.
- **[scoop](https://scoop.sh)**: A command-line installer for Windows.
- **[starship](https://starship.rs)**: A cross-shell prompt.
- **[winget](https://github.com/microsoft/winget-cli)**: Windows Package Manager CLI.

#### Powershell Modules

- **[DirColors](https://www.powershellgallery.com/packages/DirColors)**: Provides dircolors-like functionality to all System.IO.FilesystemInfo formatters.
- **[PSFzf](https://github.com/kelleyma49/PSFzf)**: A PowerShell wrapper around the fuzzy finder fzf.

#### Powershell Modules on Windows only

- **[Microsoft.WinGet.Client](https://www.powershellgallery.com/packages/Microsoft.WinGet.Client)**: PowerShell Module for the Windows Package Manager Client.

### Installed GUI Software

- **[Calibre](https://calibre-ebook.com)** ([Open-Source](https://github.com/kovidgoyal/calibre)): E-books management software. _Conditional: ebook_library._
- **[DevPod](https://devpod.sh)** ([Open-Source](https://github.com/loft-sh/devpod)): Codespaces but open-source, client-only and unopinionated. Works with any IDE and cloud. _Conditional: This is installed when both coding and container runtime flags are enabled._
- **[MusicBrainz Picard](https://picard.musicbrainz.org/)**: Music tagger and metadata editor. _Conditional: music_library, not headless._
- **[ScummVM](https://www.scummvm.org/)**: Graphic adventure game interpreter. _Conditional: gaming_device_library, not headless._
- **[VLC](https://www.videolan.org/vlc/download-macosx.html)** ([Open-Source](https://code.videolan.org/videolan/vlc)): A free and open source cross-platform multimedia player. _Conditional: video._
- **[Zed](https://zed.dev)**: A cross-platform text editor. Available via brew, installer script, scoop, or [download](https://zed.dev/download).

#### GUI Software on Windows and macOS

- **[ChatGPT](https://openai.com/chatgpt/desktop/)**: OpenAI's AI assistant desktop app.
- **[Raspberry Pi Imager](https://www.raspberrypi.org/downloads/)**: Imaging utility to install operating systems to a microSD card. _Conditional: work._
- **[Tailscale](https://tailscale.com)** ([Open-Source](https://github.com/tailscale/tailscale)): WireGuard-based mesh VPN for secure device connectivity. _Conditional: personal, non-ephemeral._
- If the gaming flag is enabled:
  - **[Steam](https://store.steampowered.com)**: A digital distribution platform for purchasing and playing video games.

#### GUI Software on Windows, macOS, and Linux

- **[1Password](https://1password.com)**: A password manager developed by AgileBits.
- **[86Box](https://www.86box.net/)**: Emulator of x86-based machines. _Conditional: retro_computing, not work._
- **[Discord](https://discord.com)**: A VoIP and instant messaging social platform. _Conditional: on Linux, amd64 only._
- **[Obsidian](https://obsidian.md)**: A powerful knowledge base that works on top of a local folder of plain text Markdown files. Available via brew, scoop, flatpak, or [download](https://obsidian.md/download).
- **[Steam Link](https://store.steampowered.com/steamlink/about)**: Stream your Steam games. _Conditional: gaming._
- **[Vivaldi](https://vivaldi.com/)**: Web browser with built-in email client focusing on customization and control. Available via brew, scoop, or flatpak.

#### GUI Software on Windows, macOS, and FreeBSD

- **[Transmission Remote GUI](https://github.com/transmission-remote-gui/transgui)** ([Open-Source](https://github.com/transmission-remote-gui/transgui)): Remote GUI for Transmission. _Conditional: not work._

#### GUI Software on Linux and FreeBSD

- **[Command Output](https://store.kde.org/p/1166510/)** ([Open-Source](https://github.com/Zren/plasma-applet-commandoutput)): KDE Plasma widget for command output in panels.
- **[Filelight](https://apps.kde.org/filelight/)** ([Open-Source](https://invent.kde.org/utilities/filelight)): KDE disk usage analyzer.
- **[Syncthing Tray](https://martchus.github.io/syncthingtray/)** ([Open-Source](https://github.com/Martchus/syncthingtray)): System tray application for Syncthing. _Conditional: user_setup, not ephemeral, not headless._

#### GUI Software on Linux

- **[TrguiNG](https://github.com/openscopeproject/TrguiNG)** ([Open-Source](https://github.com/openscopeproject/TrguiNG)): A modern Transmission remote GUI. _Conditional: not work._
- **[Vesktop](https://github.com/Vencord/Vesktop)** ([Open-Source](https://github.com/Vencord/Vesktop)): A Vencord-based desktop client for Discord. _Conditional: arm64._

#### GUI Software on Windows and macOS

- **[Readwise Reader](https://readwise.io/read)**: Save everything to one place, highlight like a pro, and replace several apps with Reader. _Conditional: not work, not ephemeral._

#### GUI Software on FreeBSD

- **[LibreWolf](https://librewolf.net/)** ([Open-Source](https://codeberg.org/librewolf)): A custom version of Firefox, focused on privacy, security, and freedom. Available via FreeBSD ports (`www/librewolf`).

#### GUI Software on Windows

- **[SquirrelDisk](https://www.squirreldisk.com/)** ([Open-Source](https://github.com/adileo/squirreldisk)): Beautiful, Cross-Platform and Super Fast Disk Usage Analysis Tool. Available via scoop, winget.
- **[SumatraPDF](https://www.sumatrapdfreader.org)**: A free PDF, eBook, XPS, DjVu, CHM, Comic Book reader for Windows.

#### GUI Software on macOS (Pre-Tahoe Only)

- **[Ice](https://icemenubar.app)** ([Open-Source](https://github.com/jordanbaird/Ice)): Powerful menu bar manager for macOS.
- **[Raycast](https://www.raycast.com)**: Productivity tool, application launcher, snippets, clipboard history, and automation.
- **[Rectangle](https://rectangleapp.com)** ([Open-Source](https://github.com/rxhanson/Rectangle)): Move and resize windows in macOS using keyboard shortcuts or snap areas.

#### GUI Software on macOS (Pre-Sonoma Only)

- **[Aerial](https://aerialscreensaver.github.io)** ([Open-Source](https://github.com/JohnCoates/Aerial)): A macOS screensaver that lets you play videos from Apple's tvOS screensaver.

#### GUI Software on macOS

- **[BlockBlock](https://objective-see.org/products/blockblock.html)**: Monitors common persistence locations and alerts whenever a persistent component is added.
- **[Brooklyn](https://github.com/pedrommcarrasco/Brooklyn)** (Open-Source): Screen saver based on animations presented during Apple Special Event Brooklyn.
- **[Carbon Copy Cloner](https://bombich.com)**: Backups and disk cloning for macOS.
- **[DaisyDisk](https://daisydiskapp.com)**: Disk space visualizer. Get a visual breakdown of your disk space in form of an interactive map, reveal the biggest space wasters, and remove them with a simple drag and drop.
- **[Deliveries](https://apps.apple.com/us/app/deliveries-a-package-tracker/id290986013)**: Track your packages with support for dozens of services. Syncs via iCloud.
- **[ForkLift](https://binarynights.com)**: Advanced dual pane file manager and file transfer client for macOS. Available via brew as `forklift`.
- **[Juicy](https://getjuicy.app)**: Battery Alerts & Health. Available via [Mac App Store](https://apps.apple.com/us/app/juicy-battery-alerts-health/id6752221257?mt=12)
- **[Karabiner-Elements](https://karabiner-elements.pqrs.org)** ([Open-Source](https://github.com/pqrs-org/Karabiner-Elements)): A powerful and stable keyboard customizer for macOS.
- **[Kagi News](https://apps.apple.com/us/app/kagi-news/id6748314243)**: Daily AI-distilled press review with global news from community-curated sources.
- **[KeepingYouAwake](https://keepingyouawake.app/)** ([Open-Source](https://github.com/newmarcel/KeepingYouAwake)): Prevents your Mac from going to sleep.
- **[Keka](https://www.keka.io/en/)** ([Open-Source](https://github.com/aonez/Keka)): The macOS file archiver.
- **[kitty](https://sw.kovidgoyal.net/kitty/)** ([Open-Source](https://github.com/kovidgoyal/kitty)): The fast, feature-rich, GPU based terminal emulator.
- **[LuLu](https://objective-see.org/products/lulu.html)**: The free, open-source firewall that aims to block unknown outgoing connections.
- **[Maccy](https://maccy.app)** ([Open-Source](https://github.com/p0deje/Maccy)): Lightweight clipboard manager for macOS.
- **[OmniOutliner](https://www.omnigroup.com/omnioutliner)**: Organize your ideas, projects, and plans in a powerful outliner.
- **[OverSight](https://objective-see.org/products/oversight.html)**: Monitors a Mac's microphone and webcam, alerting the user when the internal mic is activated, or whenever a process accesses the webcam.
- **[Parallels Desktop](https://www.parallels.com/products/desktop/)**: Run Windows, Linux, and other operating systems on Mac.
- **[PopClip](https://apps.apple.com/us/app/popclip/id445189367?mt=12&uo=4&at=10l4tL)**: Instant text actions.
- **[ReiKey](https://objective-see.org/products/reikey.html)**: Scans, detects, and monitors for software that installs keyboard event taps.
- **[Shifty](https://shifty.natethompson.io/)**: Menu bar app that provides more control over Night Shift.
- **[SwiftBar](https://swiftbar.app/)**]: Powerful macOS menu bar customization tool. _Conditional: This is installed when a container runtime is enabled, as I use this to start/stop colima._
- **[SyncThing](https://syncthing.net/)** ([Open-Source](https://github.com/syncthing/)): A continuous file synchronization program. _Conditional: user_setup, not ephemeral, not headless._
- **[Under My Roof](https://apps.apple.com/us/app/under-my-roof-home-inventory/id1524335878)**: Home inventory app for organizing and tracking your home and belongings.
- **[WiFi Explorer](https://apps.apple.com/us/app/wifi-explorer/id494803304?mt=12&uo=4&at=10l4tL)**: Best Wi-Fi Analyzer & Monitor.
- **[WiFi Signal](https://apps.apple.com/us/app/wifi-signal-status-monitor/id525912054?mt=12&uo=4&at=10l4tL)**: WiFi Connection Status Monitor.

##### Conditional GUI Software on macOS

- If the music flag is enabled:
  - **[MusicHarbor](https://apps.apple.com/us/app/musicharbor-track-new-music/id1440405750?uo=4&at=10l4tL)**: Track new music releases from your favorite artists.
- If the video flag is enabled:
  - **[Play](https://apps.apple.com/us/app/play-save-videos-watch-later/id1596506190)**: Bookmark and organize videos to watch later.
- If the work flag is enabled:
  - **[noTunes](https://github.com/tombonez/noTunes)** (Open-Source): Prevents Apple Music from launching. _Conditional: music flag not enabled._
  - **[Slack](https://slack.com/)**: Team communication and collaboration platform.
  - **[Zoom](https://zoom.us/)**: Video conferencing and online meetings.

##### Safari Extensions

- [1Password for Safari](https://apps.apple.com/us/app/1password-for-safari/id1569813296?mt=12&uo=4&at=10l4tL)
- **[DeArrow](https://apps.apple.com/us/app/dearrow/id6451469297)**: Crowdsourced replacement of clickbait YouTube titles and thumbnails.
- **[Declutter](https://apps.apple.com/us/app/declutter-for-safari/id1574021257)**: Automatically closes duplicate tabs in Safari.
- [Hush](https://apps.apple.com/us/app/hush-nag-blocker/id1544743900?uo=4&at=10l4tL) ([Open-Source](https://github.com/oblador/hush))
- **[Kagi for Safari](https://apps.apple.com/us/app/kagi-for-safari/id1622835804)**: Kagi search for Safari.
- **[Noir](https://apps.apple.com/us/app/noir/id1592917505)**: Dark mode for every website.
- **[Obsidian Web Clipper](https://apps.apple.com/us/app/obsidian-web-clipper/id6720708363)**: Clip web pages to Obsidian.
- [SessionRestore](https://apps.apple.com/us/app/sessionrestore-for-safari/id1463334954?mt=12&uo=4&at=10l4tL)
- **[Save to Reader](https://apps.apple.com/us/app/save-to-reader/id1640236961)**: Save pages to Readwise Reader.
- **[SponsorBlock](https://apps.apple.com/us/app/sponsorblock/id1573461917)**: Skip sponsorships in YouTube videos.
- **[StopTheMadness Pro](https://apps.apple.com/us/app/stopthemadness-pro/id6471380298)**: A Safari extension that stops web site annoyances and privacy violations.
- **[Tampermonkey Classic](https://apps.apple.com/us/app/tampermonkey-classic/id1482490089?mt=12&uo=4&at=10l4tL)**: Temporary replacement for Userscripts while it's being updated.
- **[Things To Get Me](https://apps.apple.com/us/app/things-to-get-me/id6447106500)**: Add products to your wish-list from anywhere while browsing in Safari.
- **[uBlock Origin Lite](https://apps.apple.com/us/app/ublock-origin-lite/id6745342698)**: An efficient content blocker for Safari.
- [Vinegar](https://apps.apple.com/us/app/vinegar-tube-cleaner/id1591303229?uo=4&at=10l4tL)

##### QuickLook Plugins

- **[Apparency](https://www.mothersruin.com/software/Apparency/)**: Preview the contents of a macOS app
- **[BetterZip](https://betterzip.com)**: A trialware file archiver. I only install this for the QuickLook plugin.
- **[Suspicious Package](https://www.mothersruin.com/software/SuspiciousPackage/)**: Preview the contents of a standard Apple installer package

#### GUI Software on Windows

- [7-Zip](https://www.7-zip.org/) ([Open-Source](https://github.com/ip7z/7zip))
- [AutoHotkey](https://www.autohotkey.com/)
- **[Bulk Crap Uninstaller](https://www.bcuninstaller.com)** ([Open-Source](https://github.com/Klocman/Bulk-Crap-Uninstaller)): Remove large amounts of unwanted applications quickly.
- **[DevDocs Desktop](https://github.com/egoist/devdocs-desktop)** (Open-Source): A full-featured desktop app for DevDocs.io.
- [Ditto](https://ditto-cp.sourceforge.io) ([Open-Source](https://github.com/sabrogden/Ditto))
- **[Gpg4win](https://www.gpg4win.org)** ([Open-Source](https://git.gnupg.org/cgi-bin/gitweb.cgi?p=gpg4win.git;a=summary)): Secure email and file encryption with GnuPG for Windows.
- [Notepad++](https://notepad-plus-plus.org/) ([Open-Source](https://github.com/notepad-plus-plus/notepad-plus-plus))
- [PowerToys](https://learn.microsoft.com/en-us/windows/powertoys/) ([Open-Source](https://github.com/microsoft/PowerToys))
- **[SnipDo](https://snipdo-app.com)**: Select a text in any application and SnipDo pops up to help you.
- **[SyncTrayzor](https://github.com/canton7/SyncTrayzor)** (Open-Source): Windows system tray app for Syncthing. _Conditional: user_setup, not ephemeral, not headless._
- **[WiFi Analyzer](https://apps.microsoft.com/detail/9NBLGGH33N0N?hl=en-US&gl=US)**: Identify Wi-Fi problems or find the best channel.
- **[Windows Firewall Control](https://www.binisoft.org/wfc)**: Managing Windows Firewall is now easier than ever.
- [Windows Terminal](https://apps.microsoft.com/store/detail/9N0DX20HK701?hl=en-us&gl=US) ([Open-Source](https://github.com/microsoft/terminal))

## Additional Docs

- **[As-Needed Software](docs/as-needed.md)**: Software I install occasionally as needed rather than on every machine, with details on how they can be installed.
- **[Formerly-Used Software](docs/formerly-used.md)**: Software I've used in the past but no longer use, with details on why I stopped using them.
- **[Operating System Installation](docs/os-installation.md)**: Step-by-step instructions for certain operating system installations using the included `os-install` and `setup-root` scripts.

## Contributing & Support

Questions, comments, feedback, and contributions are always welcome, please open an issue.

See [CONTRIBUTING.md](CONTRIBUTING.md) for ways to get started contributing to this project.

Please adhere to this project's [Code of Conduct](CODE_OF_CONDUCT.md) and follow [The Ethical Source Principles](https://ethicalsource.dev/principles/).

## License

Distributed under the terms of the [Blue Oak Model License 1.0.0](LICENSE.md) license.


[chezmoi]: https://www.chezmoi.io/
[home-manager]: https://nix-community.github.io/home-manager/
[age]: https://age-encryption.org/
[Homebrew]: https://brew.sh/
[Scoop]: https://scoop.sh/
