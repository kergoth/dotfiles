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
- **[CLI Design](home/dot_agents/skills/cli-design/SKILL.md)**: Guidelines for designing and implementing command-line interfaces, with [clig.dev](https://clig.dev/) as the baseline.
- **[Cram](home/dot_agents/skills/cram/SKILL.md)**: Write, read, and debug [cram](https://bitheap.org/cram/) functional tests (.t files).
- **[Dispatch External Model](home/dot_agents/skills/dispatch-external-model/SKILL.md)**: CLI syntax for dispatching prompts to external model agents (claude, cursor, codex, gemini).
- **[Evaluate Open-Source Project](home/dot_agents/skills/evaluate-open-source-project/SKILL.md)**: Due diligence for adopting open-source projects, plugins, or skills (trust, maintainer health, security risk).
- **[Find Session](home/dot_agents/skills/find-session/SKILL.md)**: Find and resume past Claude Code, Codex, or Cursor Agent conversations by searching session history files by keyword.
- **[Git Commits](home/dot_agents/skills/git-commits/SKILL.md)**: Personal conventions for Git commit messages, staging, history curation, and bisectability.
- **[Git PRs](home/dot_agents/skills/git-prs/SKILL.md)**: Personal conventions for pull request descriptions, templates, and reviewer-facing content.
- **[GitHub Issue Triage](home/dot_agents/skills/github-issue-triage/SKILL.md)**: End-to-end GitHub issue triage with complexity scoring and execution-lane recommendations.
- **[Issue Tracking Conventions](home/dot_agents/skills/issue-tracking-conventions/SKILL.md)**: Structural conventions for issues, epics, and bug reports across trackers.
- **[jj Commits](home/dot_agents/skills/jj-commits/SKILL.md)**: Commit policy for Jujutsu repositories (paired with the Jujutsu skill).
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

See [docs/installed.md](docs/installed.md) for installed software.

## Additional Docs

- **[Architectural Decision Records](docs/decisions/)**: Significant architectural decisions, documented using the [MADR](https://adr.github.io/madr/) standard.
- **[Installed Software](docs/installed.md)**: Installed software inventory by platform and category.
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
