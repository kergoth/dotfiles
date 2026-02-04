# Kergoth's Dotfiles and Setup Scripts

[![BlueOak 1.0.0 License](https://img.shields.io/badge/License-BlueOak%201.0.0-2D6B79.svg)](https://spdx.org/licenses/BlueOak-1.0.0.html)

This repository includes my personal application configuration and settings (dotfiles), as well as scripts for
setting up systems per my personal preferences, including software installation, at both the system and user
level.

## Prerequisites

- (On macOS) The user with admin privileges must have signed into the Mac App Store to allow `setup-system` to succeed.

## Usage

### Dotfiles setup

This setup will apply the dotfiles and perform any user-setup tasks, such as installing packages with home-manager, homebrew, etc. If system setup is desired, run `setup-system` prior to running `setup`.

If the repository has not yet been cloned:

```console
chezmoi init kergoth/dotfiles
~/.dotfiles/script/setup
```

If the repository is already cloned and you've changed directory to it:

```console
./script/setup
```

### System Setup

The setup-system script is run by a non-root user with sudo/doas access, to perform system-level setup and configuration.
This script will apply changes to the system as a whole. This may include installing packages through the package manager, installing nix, et cetera. Ideally this should be run prior to setting up the user, and should be run as a user with sudo access.

After cloning the repository, and changing directory to it, run:

```console
./script/setup-system
```

On windows (in powershell, not WSL), run this instead:

```console
./script/setup-system.ps1
```

### Operating System Installation

#### WSL2 Arch Linux Installation (ArchWSL)

- Install ArchWSL via scoop: `scoop install archwsl`
- Or download from [ArchWSL releases](https://github.com/yuk7/ArchWSL/releases)
- Run `Arch.exe` to initialize the distribution and enter as root
- Initial setup (as root):

```console
# Initialize keyring and do full system upgrade with git
pacman-key --init
pacman-key --populate
pacman -Syu --noconfirm archlinux-keyring git

# Clone dotfiles and run setup-root
cd
git clone https://github.com/kergoth/dotfiles .dotfiles
./.dotfiles/script/arch/setup-root kergoth
exit
```

- Set the new user as default: `Arch.exe config --default-user kergoth`
- Re-enter WSL as the new user: `wsl -d Arch`
- Clone the dotfiles and run setup:

```console
cd
git clone https://github.com/kergoth/dotfiles .dotfiles
./.dotfiles/script/setup-full
```

**Alternative (wget method):** If you prefer not to clone as root, you can download setup-root directly:

```console
cd
wget https://raw.githubusercontent.com/kergoth/dotfiles/main/script/arch/setup-root
sh setup-root kergoth
exit
```

The setup-root script will initialize the keyring automatically if needed.

#### WSL2 Chimera Linux Installation

- Download the latest release zip file from [ChimeraWSL](https://github.com/tranzystorekk/ChimeraWSL) (Install Chimera Linux as a WSL instance).
- Unpack `Chimera.zip` into ~/Apps/Chimera
- Run ~/Apps/Chimera/chimera.exe, which registers the new distro with WSL and unpacks the rootfs tarball, then enters the wsl as root
- Initial setup, run the setup-root script, and exit wsl:

```console
apk update
apk upgrade
apk add git
cd
git clone https://github.com/kergoth/dotfiles .dotfiles
./.dotfiles/script/chimera/setup-root
exit
```

- Set our new user as default: `~/Apps/Chimera/chimera.exe config --default-user kergoth`
- Re-enter wsl, as the new user: `wsl -d chimera`
- Clone the dotfiles repository and run the system and user setup:

```console
cd
git clone https://github.com/kergoth/dotfiles .dotfiles
./.dotfiles/script/setup-full
```

- Optionally, enable init and service management with dinit: `doas nvim /etc/wsl.conf` and add:

```ini
[boot]
systemd=true
```

- If you set systemd=true, remember to shut down WSL so it will start init when you run it next: `wsl.exe --shutdown`.

**Note**: If you set `systemd=true`, it will run all the default Chimera Linux services, including **PipeWire**, but there's no need for this given the WSL2 system distro is already running **PulseAudio**. I need to determine which default services to disable in this situation.

#### Chimera Linux Installation

- Attach the Chimera Linux Live CD ISO to a VM or USB drive and boot from it.
- If not using a `base` ISO, wait for the graphical environment to load. It will take a few seconds.
- If using a `base` ISO, log in as `anon`.
- Run the `Console` app.
- Note that the default password, when prompted, is `chimera`.
- Clone the dotfiles repository and run the os-install script:

```console
doas apk update
doas apk add git
git clone https://github.com/kergoth/dotfiles .dotfiles
doas ./.dotfiles/script/chimera/os-install
```

- After rebooting:
  - Note: By default, there will be no graphical environment available, but this will be installed by my dotfiles setup.
  - Log in as the new user and:

```console
doas dinitctl enable dhcpcd
# Wait a second for the DHCP client to get an IP address
~/.dotfiles/script/setup-full
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

### Update the dotfiles, including external files

```console
chezmoi update -R
```

### Update the dotfiles, external files, and home directory packages

```console
./script/update
```

## Manual Setup Steps

### Manual Setup Steps for macOS

- `./scripts/extras/enable-filevault`
- System Settings > Lock Screen
  - Set “Require password after screen saver begins or display is turned off” to after 5 seconds or less.

- System Settings > Privacy & Security > Security
  - Set “Allow applications downloaded from App Store and identified developers” at most.

- System Settings > Privacy & Security > Full Disk Access
  - Add Terminal, iTerm, and any other terminal emulators you use.
  - Add VSCode, and any other editors you use.

- Run vscode, enable settings sync
- Run vivaldi, enable sync
- Run deliveries, click yes to import from iCloud
- Run musicharbor, click yes to import from iCloud
- Run appcleaner, preferences, enable smartdelete
- Run alfred, preferences, advanced, enable sync to `~/Sync/App Settings/Alfred`
- Safari
  - Change the default scale to 85%
  - Add site settings icon
  - Add cloud tabs icon
  - Rearrange icons

- Syncthing Shares
  - Sync/dotfiles-local
  - Sync/App Settings
  - Library/Fonts
  - Library/Application Support/Zed/extensions

### Manual Setup Steps for Windows

- Set up all my Syncthing shares
  - `AppData/Local/Zed/extensions`
- Restore from backup:
  - `$USERPROFILE/Apps`
  - Vivaldi: `AppData/Local/Vivaldi/User Data/Default/`
  - archwsl disk image

- Run QuickLook, right click its icon, click start at login
- Create link to CapsLockCtrlEscape.exe in Startup (win-r -> shell:startup)
- Install Fonts from Sync/Fonts
- Run vscode, enable settings sync
- Remove Edge, Store, Mail from the task bar pins.

## What's Included

### Dotfiles

#### Zsh Plugins

- [fzf-tab](https://github.com/Aloxaf/fzf-tab): Replace zsh's default completion selection menu with fzf.
- [nix-zsh-completions](https://github.com/nix-community/nix-zsh-completions): ZSH Completions for Nix.
- [powerlevel10k](https://github.com/romkatv/powerlevel10k/): A Zsh theme.
- [zbell](https://gist.githubusercontent.com/jpouellet/5278239): Make Zsh print a bell when long-running commands finish.
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions): Fish-like autosuggestions for zsh.
- [zsh-bd](https://github.com/Tarrasch/zsh-bd): Jump back to a specific directory, without doing `cd ../../..`.
- [zsh-completions](https://github.com/zsh-users/zsh-completions): Additional completion definitions for Zsh.
- [zsh-git-escape-magic](https://github.com/knu/zsh-git-escape-magic): zle tweak for git command line arguments.
- [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search): ZSH port of Fish history search (up arrow).
- [zsh-manydots-magic](https://github.com/knu/zsh-manydots-magic): zle tweak for emulating ...==../.. etc.
- [zsh-nix-shell](https://github.com/chisui/zsh-nix-shell): Zsh plugin that lets you use zsh in nix-shell shells.
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting): Fish shell like syntax highlighting for Zsh.

### Fonts

- [iA-Fonts](https://github.com/iaolo/iA-Fonts): iA Writer Mono, Duo, and Quattro.
- [MesloLGS NF](https://github.com/romkatv/powerlevel10k/blob/master/font.md): Meslo Nerd Font patched for Powerlevel10k.

### Installed CLI Software

- [curl](https://curl.se): Command line tool and library for transferring data with URLs.
- [wget](https://www.gnu.org/software/wget/): A free software package for retrieving files using HTTP, HTTPS, FTP and FTPS.
- [gh](https://cli.github.com): GitHub’s official command line tool.
- [git](https://git-scm.com): A free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.
- [git-lfs](https://git-lfs.github.com): An open source Git extension for versioning large files.
- [neovim](https://neovim.io): Hyperextensible Vim-based text editor.
- [gnupg](https://www.gnupg.org): A complete and free implementation of the OpenPGP standard.

- [python](https://www.python.org): A programming language that lets you work quickly and integrate systems more effectively.
- [uv](https://github.com/astral-sh/uv): An extremely fast Python package installer and resolver, written in Rust.

- [atuin](https://github.com/ellie/atuin): ✨ Magical shell history.
- [bat](https://github.com/sharkdp/bat): A cat(1) clone with syntax highlighting and Git integration.
  - [bat-extras](https://github.com/eth-p/bat-extras): Scripts that integrate bat with various command line tools.
- [choose](https://github.com/theryangeary/choose): A human-friendly and fast alternative to cut and (sometimes) awk.
- [Claude Code](https://code.claude.com): Anthropic's agentic coding tool for your terminal. Available via brew (`claude-code`), official installer, and npm.
- [delta](https://github.com/dandavison/delta): A syntax-highlighting pager for git, diff, and grep output.
- [direnv](https://direnv.net): An extension for your shell which can load and unload environment variables depending on the current directory.
- [duf](https://github.com/muesli/duf): Disk Usage/Free Utility - a better 'df' alternative.
- [dua](https://github.com/Byron/dua-cli): View disk space usage and delete unwanted data, fast. This is a faster version of ncdu.
- [fclones](https://github.com/pkolaczk/fclones): Finds and removes duplicate files.
- [restic](https://restic.net) ([Open-Source](https://github.com/restic/restic)): Fast, secure, efficient backup program.
- [rsync](https://rsync.samba.org/): Fast, versatile file copying tool for remote and local files.
- [Tailscale](https://tailscale.com) ([Open-Source](https://github.com/tailscale/tailscale)): WireGuard-based mesh VPN that makes it easy to connect your devices securely.
- [eza](https://github.com/eza-community/eza) or [exa](https://github.com/ogham/exa): A modern replacement for ls.
- [fd](https://github.com/sharkdp/fd): A simple, fast and user-friendly alternative to 'find'.
- [fzf](https://github.com/junegunn/fzf): A command-line fuzzy finder.
- [ghq](https://github.com/x-motemen/ghq): Remote repository management made easy.
- [git-absorb](https://github.com/tummychow/git-absorb): git commit --fixup, but automatic.
- [git-imerge](https://github.com/mhagger/git-imerge): Incremental merge for git.
- [git-revise](https://github.com/mystor/git-revise): A handy tool for doing efficient in-memory commit rebases & fixups.
- [jira-cli](https://github.com/ankitpokhrel/jira-cli) (_Only on Work machines_): Feature-rich interactive Jira command line.
- [jujutsu](https://github.com/jj-vcs/jj) ([Open-Source](https://github.com/jj-vcs/jj)): Git-compatible VCS that is both simple and powerful.
- [jq](https://github.com/stedolan/jq): A lightweight and flexible command-line JSON processor.
- [ripgrep](https://github.com/BurntSushi/ripgrep): A line-oriented search tool that recursively searches the current directory for a regex pattern.
- [rusage.com](https://justine.lol/rusage/): Provides the best possible way to report resource usage statistics when launching command line programs.
- [sad](https://github.com/ms-jpq/sad): CLI search and replace | Space Age seD.
- [sd](https://github.com/chmln/sd): Intuitive find & replace CLI (sed alternative).
- [shellcheck](https://github.com/koalaman/shellcheck): A static analysis tool for shell scripts.
- [shfmt](https://github.com/mvdan/sh#shfmt): Format shell programs.
- [tealdeer](https://github.com/dbrgn/tealdeer): Simplified, example based and community-driven man pages.
- [uv](https://docs.astral.sh/uv/) ([Open-Source](https://github.com/astral-sh/uv)): An extremely fast Python package and project manager, written in Rust.
- [zoxide](https://github.com/ajeetdsouza/zoxide): A smarter cd command, inspired by z and autojump.
- [zstd](http://www.zstd.net/): Zstandard - Fast real-time compression algorithm.

#### CLI Software on Linux and macOS

- [nix](https://nixos.org): Nix is a tool that takes a unique approach to package management and system configuration.

#### CLI Software on Linux, macOS, and FreeBSD

- [patchutils](http://cyberelk.net/tim/software/patchutils/): A small collection of programs that operate on patch files.
  - On Windows, patchutils can be used via either WSL or MSYS2 (which can be installed via scoop and run as `msys2`, ex. `msys2 -c 'exec filterdiff "$@"' -`).

- [ssh-copy-id](https://www.openssh.com): Install your identity.pub in a remote machine’s authorized_keys.
  - On Windows, I have a powershell function which does this, and is aliased to `ssh-copy-id`.

- [tmux](https://github.com/tmux/tmux): An open-source terminal multiplexer.
  - There are no good options for tmux or tmux-equivalent on Windows. The closest you can get is just splits in Windows Terminal, which doesn't give you the ability to disconnect.

#### CLI Software on Linux (non-Chimera), macOS, FreeBSD, and Windows

- [unar](https://theunarchiver.com/command-line): Universal archives extractor. Available via brew, nix, and scoop.

#### CLI Software on FreeBSD

- [go](https://go.dev): An open source programming language supported by Google
  - Installed so we can `go install` various tools.

- [rust](https://www.rust-lang.org): A multi-paradigm, general-purpose programming language.
  - Installed so we can `cargo install` various tools.

#### CLI Software on macOS

- [lima](https://github.com/lima-vm/lima): Linux virtual machines, typically on macOS, for running containerd.
- [colima](https://github.com/abiosoft/colima): Container runtimes on macOS (and Linux) with minimal setup. _Conditional: This is installed when a container runtime is enabled._
- [duti](https://github.com/moretension/duti): A command-line tool to select default applications for document types and URL schemes on Mac OS X.
- [mas](https://github.com/mas-cli/mas): Mac App Store command line interface.
- [reattach-to-user-namespace](https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard): Reattach to the per-user bootstrap namespace. This is needed for tools like tmux, though tmux 2.6+ apparently incorporates this functionality already.
- [trash](https://hasseg.org/trash/): A small command-line program for OS X that moves files or folders to the trash.

#### CLI Software on Linux and FreeBSD

- [zsh](https://zsh.sourceforge.io): A shell designed for interactive use, although it is also a powerful scripting language. This is installed by default on macOS.

##### CLI Software on Arch Linux

- [openssh](https://www.openssh.com): The premier connectivity tool for remote login with the SSH protocol.
- [avahi](https://avahi.org): A system which facilitates service discovery on a local network via mDNS.
- [nss-mdns](http://0pointer.de/lennart/projects/nss-mdns/): A GNU Libc NSS module that provides mDNS host name resolution.

##### CLI Software on WSL2

- [npiperelay](https://github.com/jstarks/npiperelay): Access Windows named pipes from WSL.
- [socat](http://www.dest-unreach.org/socat/): Multipurpose relay for bidirectional data transfer. This is required for [npiperelay](https://github.com/jstarks/npiperelay).

##### CLI Software on Chimera Linux

- [podman](https://podman.io): A daemonless container engine for developing, managing, and running OCI Containers. _Conditional: This is installed when the containers flag is enabled._
- [podman-compose](https://github.com/containers/podman-compose): A script to run docker-compose.yml using podman. _Conditional: This is installed when the containers flag is enabled._
  - Note: Chimera Linux uses podman instead of docker due to potential compatibility issues with docker on its BSD userland.

#### CLI Software on Windows

- [gow](https://github.com/bmatzelle/gow): Unix command line utilities installer for Windows.
- [gsudo](https://github.com/gerardog/gsudo): Sudo for Windows.
- [recycle-bin](https://github.com/sindresorhus/recycle-bin): Move files and folders to the Windows recycle bin within command line.
- [scoop](https://scoop.sh): A command-line installer for Windows.
- [starship](https://starship.rs): A cross-shell prompt.
- [winget](https://github.com/microsoft/winget-cli): Windows Package Manager CLI.

#### Powershell Modules

- [DirColors](https://www.powershellgallery.com/packages/DirColors): Provides dircolors-like functionality to all System.IO.FilesystemInfo formatters.
- [PSFzf](https://github.com/kelleyma49/PSFzf): A PowerShell wrapper around the fuzzy finder fzf.

#### Powershell Modules on Windows only

- [Microsoft.WinGet.Client](https://www.powershellgallery.com/packages/Microsoft.WinGet.Client): PowerShell Module for the Windows Package Manager Client.

### Installed GUI Software

- [Zed](https://zed.dev): A cross-platform text editor. Available via brew, installer script, scoop, or [download](https://zed.dev/download).
- [DevPod](https://devpod.sh) ([Open-Source](https://github.com/loft-sh/devpod)): Codespaces but open-source, client-only and unopinionated. Works with any IDE and cloud. _Conditional: This is installed when both coding and container runtime flags are enabled._

#### GUI Software on Windows and macOS

- [1Password](https://1password.com): A password manager developed by AgileBits.
- [Discord](https://discord.com): A VoIP and instant messaging social platform.
- [Obsidian](https://obsidian.md): A powerful knowledge base that works on top of a local folder of plain text Markdown files. Available on Linux, macOS, and Windows via brew, scoop, flatpak, or [download](https://obsidian.md/download).
- [Vivaldi](https://vivaldi.com/): Web browser with built-in email client focusing on customization and control.
- [VLC](https://www.videolan.org/vlc/download-macosx.html) ([Open-Source](https://code.videolan.org/videolan/vlc)): A free and open source cross-platform multimedia player.
- If the gaming flag is enabled:
  - [Steam](https://store.steampowered.com): A digital distribution platform for purchasing and playing video games.

#### GUI Software on Windows

- [SquirrelDisk](https://www.squirreldisk.com/) ([Open-Source](https://github.com/adileo/squirreldisk)): Beautiful, Cross-Platform and Super Fast Disk Usage Analysis Tool. Available via scoop, winget.
- [SumatraPDF](https://www.sumatrapdfreader.org): A free PDF, eBook, XPS, DjVu, CHM, Comic Book reader for Windows.

#### GUI Software on macOS (Pre-Tahoe Only)

- [Ice](https://icemenubar.app) ([Open-Source](https://github.com/jordanbaird/Ice)): Powerful menu bar manager for macOS.
- [Raycast](https://www.raycast.com): Productivity tool, application launcher, snippets, clipboard history, and automation.
- [Rectangle](https://rectangleapp.com) ([Open-Source](https://github.com/rxhanson/Rectangle)): Move and resize windows in macOS using keyboard shortcuts or snap areas.

#### GUI Software on macOS (Pre-Sonoma Only)

- [Aerial](https://aerialscreensaver.github.io) ([Open-Source](https://github.com/JohnCoates/Aerial)): A macOS screensaver that lets you play videos from Apple's tvOS screensaver.

#### GUI Software on macOS

- [BlockBlock](https://objective-see.org/products/blockblock.html): Monitors common persistence locations and alerts whenever a persistent component is added.
- [Brooklyn](https://github.com/pedrommcarrasco/Brooklyn) (Open-Source): Screen saver based on animations presented during Apple Special Event Brooklyn.
- [Calibre](https://calibre-ebook.com) ([Open-Source](https://github.com/kovidgoyal/calibre)): E-books management software.
- [DaisyDisk](https://daisydiskapp.com): Disk space visualizer. Get a visual breakdown of your disk space in form of an interactive map, reveal the biggest space wasters, and remove them with a simple drag and drop.
- [Deliveries](https://apps.apple.com/us/app/deliveries-a-package-tracker/id290986013): Track your packages with support for dozens of services. Syncs via iCloud.
- [ForkLift](https://binarynights.com): Advanced dual pane file manager and file transfer client for macOS. Available via brew as `forklift`.
- [Juicy](https://getjuicy.app): Battery Alerts & Health. Available via [Mac App Store](https://apps.apple.com/us/app/juicy-battery-alerts-health/id6752221257?mt=12)
- [Karabiner-Elements](https://karabiner-elements.pqrs.org) ([Open-Source](https://github.com/pqrs-org/Karabiner-Elements)): A powerful and stable keyboard customizer for macOS.
- [Kagi News](https://apps.apple.com/us/app/kagi-news/id6748314243): Daily AI-distilled press review with global news from community-curated sources.
- [Keka](https://www.keka.io/en/) ([Open-Source](https://github.com/aonez/Keka)): The macOS file archiver.
- [kitty](https://sw.kovidgoyal.net/kitty/) ([Open-Source](https://github.com/kovidgoyal/kitty)): The fast, feature-rich, GPU based terminal emulator.
- [LuLu](https://objective-see.org/products/lulu.html): The free, open-source firewall that aims to block unknown outgoing connections.
- [Maccy](https://maccy.app) ([Open-Source](https://github.com/p0deje/Maccy)): Lightweight clipboard manager for macOS.
- [PopClip](https://apps.apple.com/us/app/popclip/id445189367?mt=12&uo=4&at=10l4tL): Instant text actions.
- [Readwise Reader](https://readwise.io/read): Save everything to one place, highlight like a pro, and replace several apps with Reader.
- [Shifty](https://shifty.natethompson.io/): Menu bar app that provides more control over Night Shift.
- [SwiftBar](https://swiftbar.app/)]: Powerful macOS menu bar customization tool. _Conditional: This is installed when a container runtime is enabled, as I use this to start/stop colima._
- [SyncThing](https://syncthing.net/) ([Open-Source](https://github.com/syncthing/)): A continuous file synchronization program.
- [Tailscale](https://apps.apple.com/us/app/tailscale/id1475387142): WireGuard-based mesh VPN for secure device connectivity.
- [Transmission Remote GUI](https://github.com/transmission-remote-gui/transgui) (Open-Source): A feature rich cross platform Transmission BitTorrent client. Faster and has more functionality than the built-in web GUI.
- [Under My Roof](https://apps.apple.com/us/app/under-my-roof-home-inventory/id1524335878): Home inventory app for organizing and tracking your home and belongings.
- [WiFi Explorer](https://apps.apple.com/us/app/wifi-explorer/id494803304?mt=12&uo=4&at=10l4tL): Best Wi-Fi Analyzer & Monitor.
- [WiFi Signal](https://apps.apple.com/us/app/wifi-signal-status-monitor/id525912054?mt=12&uo=4&at=10l4tL): WiFi Connection Status Monitor.

##### Conditional GUI Software on macOS

- If the gaming flag is enabled:
  - [Steam Link](https://store.steampowered.com/steamlink/about): Stream your Steam games.
- If the gaming_device_library flag is enabled:
  - [ScummVM](https://www.scummvm.org/): Graphic adventure game interpreter.
- If the music flag is enabled:
  - [MusicHarbor](https://apps.apple.com/us/app/musicharbor-track-new-music/id1440405750?uo=4&at=10l4tL): Track new music releases from your favorite artists.
- If the music_library flag is enabled:
  - [MusicBrainz Picard](https://picard.musicbrainz.org/): Music tagger and metadata editor.
- If the video flag is enabled:
  - [Play](https://apps.apple.com/us/app/play-save-videos-watch-later/id1596506190): Bookmark and organize videos to watch later.
- If the retro_computing flag is enabled:
  - [86Box](https://www.86box.net/): Emulator of x86-based machines.
- If the work flag is enabled:
  - [Slack](https://slack.com/): Team communication and collaboration platform.
  - [Zoom](https://zoom.us/): Video conferencing and online meetings.

##### Safari Extensions

- [1Password for Safari](https://apps.apple.com/us/app/1password-for-safari/id1569813296?mt=12&uo=4&at=10l4tL)
- [DeArrow](https://apps.apple.com/us/app/dearrow/id6451469297): Crowdsourced replacement of clickbait YouTube titles and thumbnails.
- [Declutter](https://apps.apple.com/us/app/declutter-for-safari/id1574021257): Automatically closes duplicate tabs in Safari.
- [Hush](https://apps.apple.com/us/app/hush-nag-blocker/id1544743900?uo=4&at=10l4tL) ([Open-Source](https://github.com/oblador/hush))
- [Kagi for Safari](https://apps.apple.com/us/app/kagi-for-safari/id1622835804): Kagi search for Safari.
- [Noir](https://apps.apple.com/us/app/noir/id1592917505): Dark mode for every website.
- [Obsidian Web Clipper](https://apps.apple.com/us/app/obsidian-web-clipper/id6720708363): Clip web pages to Obsidian.
- [SessionRestore](https://apps.apple.com/us/app/sessionrestore-for-safari/id1463334954?mt=12&uo=4&at=10l4tL)
- [Save to Reader](https://apps.apple.com/us/app/save-to-reader/id1640236961): Save pages to Readwise Reader.
- [SponsorBlock](https://apps.apple.com/us/app/sponsorblock/id1573461917): Skip sponsorships in YouTube videos.
- [StopTheMadness Pro](https://apps.apple.com/us/app/stopthemadness-pro/id6471380298): A Safari extension that stops web site annoyances and privacy violations.
- [Tampermonkey Classic](https://apps.apple.com/us/app/tampermonkey-classic/id1482490089?mt=12&uo=4&at=10l4tL): Temporary replacement for Userscripts while it's being updated.
- [Things To Get Me](https://apps.apple.com/us/app/things-to-get-me/id6447106500): Add products to your wish-list from anywhere while browsing in Safari.
- [uBlock Origin Lite](https://apps.apple.com/us/app/ublock-origin-lite/id6745342698): An efficient content blocker for Safari.
- [Vinegar](https://apps.apple.com/us/app/vinegar-tube-cleaner/id1591303229?uo=4&at=10l4tL)

##### QuickLook Plugins

- [Apparency](https://www.mothersruin.com/software/Apparency/): Preview the contents of a macOS app
- [BetterZip](https://betterzip.com): A trialware file archiver. I only install this for the QuickLook plugin.
- [Suspicious Package](https://www.mothersruin.com/software/SuspiciousPackage/): Preview the contents of a standard Apple installer package

#### GUI Software on Windows

- [7-Zip](https://www.7-zip.org/) ([Open-Source](https://github.com/ip7z/7zip))
- [AutoHotkey](https://www.autohotkey.com/)
- [Bulk Crap Uninstaller](https://www.bcuninstaller.com) ([Open-Source](https://github.com/Klocman/Bulk-Crap-Uninstaller)): Remove large amounts of unwanted applications quickly.
- [DevDocs Desktop](https://github.com/egoist/devdocs-desktop) (Open-Source): A full-featured desktop app for DevDocs.io.
- [Ditto](https://ditto-cp.sourceforge.io) ([Open-Source](https://github.com/sabrogden/Ditto))
- [Gpg4win](https://www.gpg4win.org) ([Open-Source](https://git.gnupg.org/cgi-bin/gitweb.cgi?p=gpg4win.git;a=summary)): Secure email and file encryption with GnuPG for Windows.
- [Notepad++](https://notepad-plus-plus.org/) ([Open-Source](https://github.com/notepad-plus-plus/notepad-plus-plus))
- [PowerShell](https://learn.microsoft.com/en-us/powershell/) ([Open-Source](https://github.com/PowerShell/PowerShell))
- [PowerToys](https://learn.microsoft.com/en-us/windows/powertoys/) ([Open-Source](https://github.com/microsoft/PowerToys))
- [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/) ([Open-Source](https://git.tartarus.org/?p=simon/putty.git))
- [Rufus](https://rufus.ie/) ([Open-Source](https://github.com/pbatard/rufus))
- [SnipDo](https://snipdo-app.com): Select a text in any application and SnipDo pops up to help you.
- [SyncTrayzor](https://github.com/canton7/SyncTrayzor) (Open-Source)
- [WiFi Analyzer](https://apps.microsoft.com/detail/9NBLGGH33N0N?hl=en-US&gl=US): Identify Wi-Fi problems or find the best channel.
- [Windows Firewall Control](https://www.binisoft.org/wfc): Managing Windows Firewall is now easier than ever.
- [Windows Terminal](https://apps.microsoft.com/store/detail/9N0DX20HK701?hl=en-us&gl=US) ([Open-Source](https://github.com/microsoft/terminal))

### Installed Software on the Steam Deck

- [Decky Loader](https://decky.xyz/): A plugin loader for the Steam Deck.
- [CryoUtilities](https://github.com/CryoByte33/steam-deck-utilities): A utility to improve performance and help manage storage on Steam Deck.
- [EmuDeck](https://www.emudeck.com): Emulation made easy on steamOS.
- [Shortix](https://github.com/Jannomag/shortix): A script that creates human readable symlinks for Proton game prefix.
- [SteamDeckGyroDSU](https://github.com/kmicki/SteamDeckGyroDSU): DSU (cemuhook protocol) server for motion data running on Steam Deck.
- [Firefox](https://www.mozilla.org/en-US/firefox/): A fast, private, and secure web browser.
- [Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal): Manage Flatpak permissions.
- [Protontricks](https://github.com/Matoking/protontricks): A wrapper that does winetricks things for Proton enabled games.
- [Ludusavi](https://github.com/mtkennerly/ludusavi): Backup tool for PC game saves.
- [Google Chrome](https://www.google.com/chrome/): A fast, secure, and free web browser.
  - Only installed to use Kiosk mode for site-specific browsers from Game Mode, which I automatically set up via Steam ROM Manager from my ROM Library setup.

#### Installed CLI Software on the Steam Deck

- [pkgx](https://pkgx.sh): A blazingly fast, standalone, cross‐platform binary that runs anything.
- [rclone](https://github.com/rclone/rclone): Rsync for cloud storage.

#### Installed Decky Plugins on the Steam Deck

- [NonSteamLaunchers](https://github.com/moraroy/NonSteamLaunchers-On-Steam-Deck): A Decky Plugin for the integration of Non-Steam launchers and the games installed with them.

#### Installed Decky Plugins on the Steam Deck via ROM Library, not this setup

- [Bash Shortcuts](https://github.com/SDH-Stewardship/bash-shortcuts): A Steam Deck plugin for creating custom shortcuts that can be launched from the Quick Access Menu.
- [Deck Settings](https://github.com/davocarli/sharedeck-y): A Decky Plugin for browsing recommended Steam Deck game settings from [ShareDeck](https://sharedeck.games/) and [SteamDeckHQ](https://steamdeckhq.com/).
- [GOG Extension](https://www.patreon.com/junkstore/shop/gog-extension-302140) for the [Junk-Store](https://github.com/ebenbruyns/junkstore) Decky Plugin

## Apps I install on an as-needed basis

### As needed CLI Software

- [asciinema](https://asciinema.org/)]: Recording terminal sessions and sharing them on the web. Available via brew, nix, and python.
- [aria2](https://github.com/aria2/aria2): A lightweight multi-protocol & multi-source, cross platform download utility operated in command-line. It supports HTTP/HTTPS, FTP, SFTP, BitTorrent and Metalink. Available via brew, nix, and scoop.
- [broot](https://github.com/Canop/broot): A new way to see and navigate directory trees. Available via brew, nix, scoop, and cargo.
- [chars](https://github.com/antifuchs/chars). Tool to display names and codes for unicode codepoints. Available via brew, nix, and cargo.
- [csview](https://github.com/wfxr/csview): 📠 Pretty and fast csv viewer for cli with cjk/emoji support. Available via brew, nix, scoop, and cargo.
- [csvkit](https://github.com/wireservice/csvkit): A suite of utilities for converting to and working with CSV. Available via brew, nix, and python.
- [dasel](https://github.com/TomWright/dasel): Select, put and delete data from JSON, TOML, YAML, XML and CSV files with a single tool. Available via brew, nix, scoop, and go.
- [dirdiff](https://github.com/OCamlPro/dirdiff): Efficiently compute the differences between two directories. Available via cargo as `dirdiff-ocamlpro`.
- [dog](https://github.com/ogham/dog): A command-line DNS client. Available via brew as `dog`, nix as `dogdns`, and cargo from the source.
- [doxx](https://github.com/bgreenwell/doxx): Expose the contents of .docx files without leaving your terminal. Available via cargo from the source.
- [entr](https://github.com/eradman/entr): Run arbitrary commands when files change. Available via brew and nix.
- [eva](https://github.com/nerdypepper/eva): A simple calculator REPL, similar to bc. Available via brew, nix, and cargo.
- [fast](https://github.com/ddo/fast): Minimal zero-dependency utility for testing your internet download speed from terminal. Available via nix as `fast-cli` and go.
- [ffmpeg](https://ffmpeg.org): A complete, cross-platform solution to record, convert and stream audio and video. Available via brew, nix, and scoop.
- [flint](https://github.com/pengwynn/flint): Check your project for common sources of contributor friction. Available via brew as `flint-checker` and go.
- [git-filter-repo](https://github.com/newren/git-filter-repo): Quickly rewrite git repository history (filter-branch replacement).
- [glab](https://gitlab.com/gitlab-org/cli): A GitLab CLI tool bringing GitLab to your command line. Available via system packages (Arch: `glab`, FreeBSD: `glab`), Nix, Homebrew, MacPorts, scoop, winget (`GLab.GLab`), and eget.
- [go](https://go.dev): An open source programming language supported by Google
- [hexyl](https://github.com/sharkdp/hexyl): A simple hex viewer for the terminal. Available via brew, nix, and cargo.
- [htop](https://htop.dev): An interactive process viewer. Available via brew and nix.
- [httpie](https://github.com/httpie/httpie): A command-line HTTP client. Available via brew, nix, and python.
- [huniq](https://github.com/koraa/huniq): Command line utility to remove duplicates from the given input. Available via nix and cargo. Uses less memory than awk/uniq-seen. Rarely needed.
- [hyperfine](https://github.com/sharkdp/hyperfine): A command-line benchmarking tool. Available via brew, nix, and cargo.
- [jc](https://github.com/kellyjonbrazil/jc): CLI tool and python library that converts the output of popular command-line tools, file-types, and common strings to JSON, YAML, or Dictionaries. Available via brew, nix, scoop, and pypi.
- [petname](https://github.com/dustinkirkland/petname): Generate human readable random names. Available via pypi and cargo.
- [procs](https://github.com/dalance/procs): A modern replacement for ps written in Rust. Available via brew, nix, scoop, and cargo.
- [pup](https://github.com/ericchiang/pup): A command line tool for processing HTML. Available via brew, nix, and go.
- [qemu](https://www.qemu.org): A generic and open source machine emulator and virtualizer. Available via brew, nix, scoop, FreeBSD Ports, winget (as SoftwareFreedomConservancy.QEMU), apk on chimera linux.
- [rclone](https://github.com/rclone/rclone): Rsync for cloud storage. Available via brew, nix, and scoop.
- [rust](https://www.rust-lang.org): A multi-paradigm, general-purpose programming language.
- [titlecase](https://github.com/wezm/titlecase): A small tool that capitalizes English text. Available via cargo.
- [vivid](https://github.com/sharkdp/vivid): A generator for the LS_COLORS environment variable. Available via brew, nix, and cargo.
- [yt-dlp](https://github.com/yt-dlp/yt-dlp): A feature-rich command-line audio/video downloader. Available via brew, nix, scoop, winget, pacman, FreeBSD ports, pip/uv, and release binaries. Often requires `ffmpeg` and `deno` binaries.
  - The release binary can quickly be installed with eget: `eget --upgrade-only --asset='^zip' --to=~/.local/bin/yt-dlp yt-dlp/yt-dlp`

#### On my NAS, to download what I own

- [lgogdownloader](https://github.com/Sude-/lgogdownloader): Unofficial downloader for GOG.com. Available via brew and nix.

#### To deal with icons and images

- [icoutils](https://www.nongnu.org/icoutils/): A set of command-line programs for extracting and converting images in Microsoft Windows(R) icon and cursor files. Available via brew and nix.
- [imagemagick](https://imagemagick.org): Create, edit, compose, or convert digital images. Available via brew, nix, and scoop.

#### For [beets](https://beets.io)

- [mp3val](https://mp3val.sourceforge.net): A small, high-speed, free software tool for checking MPEG audio files' integrity. Available via brew and nix. Also available as direct binary download for Windows.
- [par2cmdline](https://github.com/Parchive/par2cmdline): Available via brew as `par2`, nix, and scoop.

#### As Needed CLI Software for macOS

- [makeicns](http://www.amnoid.de/icns/makeicns.html): Create icns files from the command line. Available via brew.
- [Mole](https://github.com/tw93/Mole): All-in-one macOS system optimization tool for cleanup, uninstalling apps, disk analysis, and system monitoring. Available via brew as `mole`.
- [mist-cli](https://github.com/ninxsoft/mist-cli): Mac command-line tool that automatically downloads macOS Firmwares / Installers. Available via brew.
- [terminal-notifier](https://github.com/julienXX/terminal-notifier): A command-line tool to send macOS User Notifications. Available via brew and nix.

#### As Needed CLI Software for Windows

- [Build Tools for Visual Studio 2022](https://visualstudio.microsoft.com/downloads/): These Build Tools allow you to build Visual Studio projects from a command-line interface.

### As Needed GUI Software

- [86Box](https://86box.net/): Emulator for vintage IBM PC and compatibles. Available via brew as `86box` and direct download.
- [Raspberry Pi Imager](https://www.raspberrypi.org/downloads/): Imaging utility to install operating systems to a microSD card. Available via brew as `raspberry-pi-imager`, winget as `RaspberryPiFoundation.RaspberryPiImager`, and scoop as `extras/raspberry-pi-imager`.
- [Battle.net](https://us.shop.battle.net/en-us?from=root): Blizzard games client. Available via brew as `battle-net`.
- [CPDT (Cross Platform Disk Test)](https://www.magesw.com/cpdt/): A disk benchmarking tool for Windows, macOS, and Linux. Available via direct download.
- [czkawka](https://github.com/qarmin/czkawka): Multi functional app to find duplicates, empty folders, similar images etc.
- [dupeGuru](https://dupeguru.voltaicideas.net): A cross-platform GUI tool to find duplicate files in a system.
- [Eddie](https://eddie.website/) ([Open-Source](https://github.com/AirVPN/Eddie)): VPN client for AirVPN with OpenVPN and WireGuard support. Available via brew as `eddie` and winget as `AirVPN.Eddie`.
- [HandBrake](https://handbrake.fr/): The open source video transcoder. Available via brew as `handbrake` and winget as `HandBrake.HandBrake`.
- [jDownloader](https://jdownloader.org): A download management tool. Available via brew as `jdownloader`.
- [Kegworks](https://github.com/Kegworks-App/Kegworks): A user-friendly tool used to make wine wrapped ports of Windows software for macOS. Formerly Wineskin Winery.
- [LocalSend](https://localsend.org): Share files to nearby devices. Available via brew as `localsend`, winget as `LocalSend.LocalSend`, and scoop as `localsend`.
- [Malwarebytes](https://www.malwarebytes.com): Warns about malware, adware and spyware.
- [MusicBrainz Picard](https://picard.musicbrainz.org): A cross-platform music tagger. Available via brew as `musicbrainz-picard`, nix as `picard`, Microsoft Store, winget as `MusicBrainz.Picard`, and scoop as `picard`.
- [Ollama](https://ollama.com): Get up and running with large language models locally. Available via brew as `ollama`.
- [Steam](https://store.steampowered.com): A digital distribution platform. Available via brew, nix, and winget as `Valve.Steam`.
- [Subler](https://subler.org): A macOS app to mux and tag mp4 files. Available via brew as `subler`.
- [SyncTERM](https://syncterm.bbsdev.net/): BBS terminal program. Available via brew as `syncterm` and direct download for Windows.
- [Transmission](https://transmissionbt.com): A Fast, Easy and Free Bittorrent Client for macOS, Windows and Linux.
- [Video Duplicate Finder](https://github.com/0x90d/videoduplicatefinder): Cross-platform software to find duplicated video (and image) files on hard disk based on similiarity.

#### As Needed GUI Software for Windows and macOS

- [SD Card Formatter](https://www.sdcard.org/downloads/formatter/): Official SD Memory Card Formatter from the SD Association for formatting SD/SDHC/SDXC cards.

#### As Needed GUI Software for macOS

- [Adapter](https://macroplant.com/adapter): Convert Video, Audio and Images. Available via brew as `adapter`.
- [Mist](https://github.com/ninxsoft/Mist): Utility that automatically downloads macOS firmwares and installers. Available via brew as `mist` (cask).
- [AmorphousDiskMark](https://katsurashareware.com/amorphousdiskmark/): Disk benchmark utility. Available via brew as `amorphousdiskmark`.
- [AnyToISO](https://www.crystalidea.com/anytoiso): Convert CD/DVD images to ISO format or extract files from them. Available via brew as `anytoiso`.
- [Apple Configurator](https://support.apple.com/apple-configurator): Configure and deploy iPhone, iPad, and Apple TV. Available via Mac App Store.
- [Audio Overload](https://www.bannister.org/software/ao.htm): Emulator for retro video game music. Available via Mac App Store (via mas as id `1512000244`).
- [Blackmagic Disk Speed Test](https://apps.apple.com/us/app/blackmagic-disk-speed-test/id425264550): Test your disk performance. Available via Mac App Store.
- [Burn](https://burn-osx.sourceforge.io/Pages/English/home.html): Simple but advanced burning for Mac OS X. Optional, as disk images can be burned with Finder or hdiutil. Available via brew as `burn`.
- [Byword](https://bywordapp.com): Markdown editor. Available via Mac App Store.
- [DeltaPatcher](https://github.com/marco-calautti/DeltaPatcher): GUI and CLI application for creating and applying BPS, IPS, UPS, and xdelta3 binary patches. Available via brew as `deltapatcher`.
- [Exporter](https://apps.apple.com/us/app/exporter/id1099120373): Export Apple Notes to various formats. Available via Mac App Store.
- [Fluid](https://fluidapp.com): Turn Your Favorite Web Apps into Real Mac Apps. Available via brew as `fluid`.
- [Gemini 2](https://macpaw.com/gemini): The intelligent duplicate file finder. Available via brew as `gemini`.
- [Kindle](https://www.amazon.com/kindle-dbs/fd/kcp): Read Kindle books on your Mac. Available via brew as `kindle`.
- [KnockKnock](https://objective-see.org/products/knockknock.html): See what's persistently installed on your Mac.
- [Marked 2](https://marked2app.com): Markdown previewer. Available via brew as `marked`.
- [MuffinTerm](https://apps.apple.com/us/app/muffinterm/id1583236494): A terminal emulator for macOS crafted for the classic BBS experience.
- [Numbers](https://www.apple.com/numbers/): Create impressive spreadsheets. Available via Mac App Store.
- [Onyx](https://www.titanium-software.fr/en/onyx.html): Verify system files structure, run miscellaneous maintenance and more. Available via brew as `onyx`.
- [Pages](https://www.apple.com/pages/): Documents that stand apart. Available via Mac App Store.
- [PhotoSweeper](https://overmacs.com): A fast & powerful duplicate photos cleaner for Mac. Available via brew as `photosweeper-x`.
- [Pixelmator Classic](https://www.pixelmator.com/mac/): Powerful, full-featured image editor for Mac. Available via Mac App Store.
- [Platypus](https://sveinbjorn.org/platypus): Create native Mac applications from command line scripts. Available via brew as `platypus`.
- [Pocket Sync](https://github.com/neil-morrison44/pocket-sync): Manage your Analogue Pocket's games, saves, and more. Available via brew as `pocket-sync`.
- [SiteSucker](https://ricks-apps.com/osx/sitesucker/): Download websites from the Internet. Available via Mac App Store.
- [TaskExplorer](https://objective-see.org/products/taskexplorer.html): Explore all the tasks (processes) running on your Mac with TaskExplorer.
- [TestFlight](https://developer.apple.com/testflight/): Test beta versions of apps. Available via Mac App Store.
- [UTM](https://mac.getutm.app/) ([Open-Source](https://github.com/utmapp/UTM)): Virtual machine manager for macOS. Available via brew as `utm` and Mac App Store.
- [XLD](https://tmkk.undo.jp/xld/index_e.html): Lossless audio decoder.

#### As Needed GUI Software for Windows

- [Autoruns](https://learn.microsoft.com/en-us/sysinternals/downloads/autoruns) (from [Sysinternals](https://learn.microsoft.com/en-us/sysinternals/)): See what programs are configured to startup automatically when your system boots and you login.
- [BleachBit](https://www.bleachbit.org): Clean Your System and Free Disk Space. Available via winget as `BleachBit.BleachBit`.
- [Exact Audio Copy](https://www.exactaudiocopy.de): Audio grabber for audio CDs using standard CD and DVD-ROM drives
- [foobar2000](https://www.foobar2000.org): Advanced freeware audio player. Available via winget as `PeterPawlowski.foobar2000` and scoop as `foobar2000`.
- [ImDisk](https://sourceforge.net/projects/imdisk-toolkit/): Mount image files of hard drive, cd-rom or floppy.
- [ImgBurn](https://www.imgburn.com): A lightweight CD / DVD / HD DVD / Blu-ray burning application. Available via winget as `LIGHTNINGUK.ImgBurn`.
- [OSFMount](https://www.osforensics.com/tools/mount-disk-images.html): Mount raw and other disk image files as virtual drives (forensic-style, typically read-only). Available via winget as `PassmarkSoftware.OSFMount`.
- [Paint.NET](https://getpaint.net): Free image and photo editing software for Windows. Available via scoop as `paint.net` and winget as `dotPDNLLC.paintdotnet`.
- [Process Explorer](https://learn.microsoft.com/en-us/sysinternals/downloads/process-explorer) (from [Sysinternals](https://learn.microsoft.com/en-us/sysinternals/)): Find out what files, registry keys and other objects processes have open, which DLLs they have loaded, and more.
- [WinCDEmu](https://wincdemu.sysprogs.org/): Open-source CD/DVD/BD emulator for mounting optical disc images (ISO, CUE/BIN, MDF/MDS, NRG, CCD/IMG). Available via scoop as `extras/wincdemu`.
- [WinImage](https://www.winimage.com/winimage.htm): A fully-fledged disk-imaging suite for easy creation, reading and editing of many image formats and fileystems.
- [WinSCP](https://winscp.net/): A popular SFTP client and FTP client for Microsoft Windows. Available via scoop, and winget as `WinSCP.WinSCP`.

#### As Needed GUI Software for Windows and Linux

- [HexChat](https://hexchat.github.io): An IRC client based on XChat. Available via brew, nix, scoop, and winget as `HexChat.HexChat`.

## Formerly-Used

### Formerly-Used Services

- [Instapaper](https://www.instapaper.com): A service for saving web pages for later reading.
- [IRCCloud](https://www.irccloud.com/): IRC client. When I do use IRC, I just use a local client on an as-needed basis.

### Formerly-Used Fonts

- [Monaspace](https://github.com/githubnext/monaspace)
- [Recursive](https://www.recursive.design) Code
- [Fira Code](https://github.com/tonsky/FiraCode)
- [Input](https://input.djr.com) Mono Narrow
- [Inconsolata](https://levien.com/type/myfonts/inconsolata.html): See also [Google Fonts](https://fonts.google.com/specimen/Inconsolata)
- [Terminus](https://terminus-font.sourceforge.net)
- [DejaVu](https://dejavu-fonts.github.io) Sans Mono
- [Leonine Sans Mono](https://www.leonerd.org.uk/hacks/hints/leoninesansmono.html)
- [Bitstream Vera](https://web.archive.org/web/20210314185159/https://www.gnome.org/fonts/) Sans Mono: See [download](https://download.gnome.org/sources/ttf-bitstream-vera/1.10/)
- [Envy Code R](https://damieng.com/blog/2008/05/26/envy-code-r-preview-7-coding-font-released) (Occasional Use)

### Formerly-Used CLI Software

- [pipx](https://pypi.org/project/pipx/): Install and run python applications in isolated environments. Superceded by **uv tool** in my workflows.
- [git-branchless](https://github.com/arxanas/git-branchless): High-velocity, monorepo-scale workflow for Git. I rarely used this, and there are other options for this workflow.
- [sapling](https://sapling-scm.com): A Scalable, User-Friendly Source Control System. Evaluated but not actively used in my workflows.
- [GNU Screen](https://www.gnu.org/software/screen): A terminal multiplexer. Replaced by tmux.
- [Bitlbee](https://www.bitlbee.org): An IRC to other chat networks gateway.
- [Centericq](https://en.wikipedia.org/wiki/Centericq): A text mode menu- and window-driven instant messaging interface.
- [weechat](https://weechat.org): A fast, light and extensible chat client.
- [irssi](https://irssi.org): A modular chat client that is most commonly known for its text mode user interface.
- [EPIC](https://www.epicsol.org): The Enhanced Programmable IRC-II Client.
- [BitchX](https://bitchx.sourceforge.net): An IRC client.
- [ircii](http://www.eterna23.net/ircii/): A terminal-based IRC and ICB client.
- [abduco](https://www.brain-dump.org/projects/abduco): Session manager.
- [dvtm](https://www.brain-dump.org/projects/dvtm): Dynamic virtual terminal manager.
- [dtach](https://dtach.sourceforge.io): Emulates the detach feature of screen.
- [asdf](https://asdf-vm.com): Version manager.
- [pyenv](https://github.com/pyenv/pyenv): Python version manager.

### Formerly-Used GUI Software

- [BBEdit](https://www.barebones.com/products/bbedit/): A professional HTML and text editor for macOS.
- [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/new/): A web browser.
- [Google Chrome](https://www.google.com/chrome/): A web browser.
- [Tor Browser](https://www.torproject.org): Anonymity Online.
- [Mozilla Thunderbird](https://www.thunderbird.net): Email client.
- [Opera Browser](https://www.opera.com): Web browser.
- [Chromium](https://www.chromium.org): Web browser.
- [Resilio Sync](https://www.resilio.com): File synchronization. Formerly **BitTorrent Sync**.
- [SpiderOak](https://spideroak.com): File synchronization.
- [Dropbox](https://www.dropbox.com): File synchronization.
- [Pidgin](https://pidgin.im): A chat client.
- [XChat](https://xchat.org): IRC chat client.
- [Clementine](https://www.clementine-player.org): Music player.
- VMWare Player
- VMWare Workstation
- [VirtualBox](https://www.virtualbox.org): Powerful x86 and AMD64/Intel64 virtualization software for creating and managing virtual machines.
- [Vagrant](https://www.vagrantup.com): Tool for building and managing virtual machines.
- [Sublime Text](https://www.sublimetext.com): Text editor.
- [Visual Studio Code](https://code.visualstudio.com) ([Open-Source](https://github.com/Microsoft/vscode)): Open-source code editor. Replaced by **Zed**.
- [Alacritty](https://alacritty.org): Terminal emulator.
- [Bear](https://bear.app): A beautiful, flexible writing app for crafting notes and prose.
- [Simplenote](https://simplenote.com): An easy way to keep notes, lists, ideas, and more.
- [Workflowy](https://workflowy.com): Organize your brain.
- [EverNote](https://evernote.com): A note-taking app.
- LibreWolf

### Formerly-Used macOS Software

- [AppCleaner](https://freemacsoft.net/appcleaner/): A small application which allows you to thoroughly uninstall unwanted apps.
  Now that I primarily use ForkLift, which has its own version of this, I no longer need the standalone version.
- [Bartender](https://www.macbartender.com): Organize your menu bar icons. Replaced by Hidden bar, then Ice.
- [CleanMyDrive 2](https://apps.apple.com/us/app/cleanmydrive-2/id523620159?mt=12&uo=4&at=10l4tL)
- [Colloquy](https://colloquy.app) ([Source](https://github.com/colloquy/colloquy)): An advanced IRC, SILC & ICB client.
- [DevDocs for macOS](https://github.com/dteoh/devdocs-macos) (Open-Source): An unofficial [DevDocs API Documentation](https://devdocs.io/) viewer for macOS.
  Deprecated in homebrew due to gatekeeper.
- [f.lux](https://justgetflux.com): Software to make your life better. Replaced by macOS Night Shift.
- [FlyCut](https://apps.apple.com/us/app/flycut-clipboard-manager/id442160987?mt=12&uo=4&at=10l4tL): Clipboard manager.
- [GoodLinks](https://apps.apple.com/us/app/goodlinks/id1474335294?uo=4&at=10l4tL): Save links, read later. Replaced by **Readwise Reader**.
- [Hidden Bar](https://apps.apple.com/us/app/hidden-bar/id1452453066?mt=12&uo=4&at=10l4tL) ([Open-Source](https://github.com/dwarvesf/hidden)): Hide menubar items. Replaced by **Ice**.
- [Itsycal for Mac](https://www.mowglii.com/itsycal/): A tiny menu bar calendar. I mostly just click on the date/time and see the calendar widget in the notification panel now.
- [Jumpcut](https://jumpcut.sourceforge.io): Clipboard manager.
- [LilyView](https://apps.apple.com/us/app/lilyview/id529490330?mt=12&uo=4&at=10l4tL)
- [LimeChat](http://limechat.net/mac/) ([Open-Source](http://github.com/psychs/limechat)): An IRC client for Mac OS X.
- [MacDown](https://macdown.uranusjr.com): Markdown editor.
- [MacVim](https://macvim-dev.github.io/macvim): Vim - the text editor - for macOS
- [Magnet](https://magnet.crowdcafe.com): Organize your workspace. Replaced by Rectangle.
- [QLColorCode](https://github.com/anthonygelibert/QLColorCode) (Open-Source): QuickLook plugin for syntax highlighting source code. No longer maintained.
- [qlImageSize](https://github.com/Nyx0uf/qlImageSize) (Open-Source): QuickLook plugin to display image size and resolution. No longer needed.
- [QLMarkDown](https://github.com/toland/qlmarkdown) (Open-Source): QuickLook plugin for Markdown files. No longer maintained.
- [QLPrettyPatch](https://github.com/atnan/QLPrettyPatch) (Open-Source): QuickLook plugin for patch files. No longer maintained.
- [QLStephen](https://github.com/whomwah/qlstephen) (Open-Source): QuickLook plugin for plain text files without extensions. No longer maintained.
- [quicklook-csv](https://github.com/p2/quicklook-csv) (Open-Source): QuickLook plugin for CSV files. No longer maintained.
- [QuickLookASE](https://github.com/rsodre/QuickLookASE) (Open-Source): QuickLook plugin for Adobe ASE Color Swatches. No longer needed.
- [QuickLookJSON](http://www.sagtau.com/quicklookjson.html): QuickLook plugin for JSON files. No longer maintained.
- [QuickSilver](https://qsapp.com): Launcher.
- [SwiftDefaultApps](https://github.com/Lord-Kamina/SwiftDefaultApps) (Open-Source): A preference pane to view and change default application associations. Last release in 2019.
- [Textual](https://www.codeux.com/textual/): Application for interacting with Internet Relay Chat (IRC) chatrooms. Available via brew.
- [TotalFinder](https://totalfinder.binaryage.com): Finder enhancement.
- [UnPlugged](https://apps.apple.com/us/app/unplugged/id423123087?mt=12&uo=4&at=10l4tL): Notifications for power plug/unplug as well as battery discharging at percentages.
- [WebPQuickLook](https://github.com/emin/WebPQuickLook) (Open-Source): QuickLook plugin for WebP image files. No longer needed.
- [Wineskin Winery](https://github.com/Gcenx/WineskinServer): A user-friendly tool used to make ports of Microsoft Windows software to macOS. Replaced by **Kegworks**.
- [WhatsYourSign](https://objective-see.org/products/whatsyoursign.html): Add a menu item to Finder to display a file's cryptographic information.

### Formerly-Used Linux Software

- [Gnome Evolution](https://gitlab.gnome.org/GNOME/evolution/-/wikis/home): Email client.
- [i3 window manager](https://i3wm.org): Tiling window manager.
- [awesome window manager](https://awesomewm.org): Tiling window manager.
- [suckless terminal](https://st.suckless.org): Terminal emulator.
- [rxvt-unicode](https://software.schmorp.de/pkg/rxvt-unicode.html): Terminal emulator. I still use this on Linux desktops, but don't often use Linux desktops anymore, and I may end up switching to alacritty, kitty, etc.

### Formerly-Used Windows Software

- [ACDSee](https://en.wikipedia.org/wiki/ACDSee). Loved this as an ultralight image viewer in the past, but it grew bloated over time, so was replaced by Irfan View or XnView, as needed.
- [Winamp](https://en.wikipedia.org/wiki/Winamp): This was the way before I switched to foobar2000 long ago.
- [ConEMU](https://conemu.github.io): Terminal emulator.
- [Console2](https://sourceforge.net/projects/console/): Terminal emulator.
- [Central Point PC Tools](<https://en.wikipedia.org/wiki/PC_Tools_(software)>) for DOS and Windows
- [K-Meleon](http://kmeleonbrowser.org): Lightweight web browser.
- [Powerdesk](https://www.vcom.com/power-desk-pro)
- [WinRAR](https://www.rarlab.com)
- [WinZip](https://winzip.com/)
- [K-Lite Codec Pack](https://codecguide.com)
- [Windows Media Player Classic](https://en.wikipedia.org/wiki/Media_Player_Classic)
- [Foxit Reader](https://www.foxit.com/pdf-reader/)
- [HWiNFO](https://www.hwinfo.com/)
- [Daemon Tools](https://www.daemon-tools.cc/home)
- [Alcohol 52%](http://www.alcohol-soft.com/install.php?pid=Alcohol52_FE__2.0.3.6850&SFA=1)
- [Alcohol 120%](http://www.alcohol-soft.com/): CD/DVD burning software.
- [CloneCD](https://en.wikipedia.org/wiki/CloneCD)
- [Nero Burning ROM](https://en.wikipedia.org/wiki/Nero_Burning_ROM)
- [CDBurnerXP](https://cdburnerxp.se/)
- [Clover](http://en.ejie.me)
- [QTTabBar](https://qttabbar.wikidot.com) ([Open-Source](https://github.com/indiff/qttabbar)): Windows Explorer tabbed browsing.
- [TweakUI](https://en.wikipedia.org/wiki/TweakUI): Windows system settings. From the Windows 95 and Windows XP PowerToys from Microsoft.
- [Eudora](<https://en.wikipedia.org/wiki/Eudora_(email_client)>): Email client.
- [pine](<https://en.wikipedia.org/wiki/Pine_(email_client)>): Email client.
- [mutt](<https://en.wikipedia.org/wiki/Mutt_(email_client)>): Email client.
- nlite
- vlite
- ninite

#### Formerly-Used in Windows 3.x

- Bitstream MakeUp for Windows: Typographic special effects for desktop publishing.
- [Timeworks Publish-It!](https://en.wikipedia.org/wiki/Timeworks_Publisher#Publish-It!): Desktop publishing.

#### Formerly-Used in Windows 95/98

- [McAfee Nuts & Bolts](https://archive.org/details/mc-afee-nuts-and-bolts-98-1999-02-english-cd): Utility suite.

### Formerly-Used DOS Software

- [Mace Utilities](https://winworldpc.com/product/mace-utilities) from Paul Mace Software, for DOS. I used this much less than the others.
- PFS Professional Write
- [PFS Professional File](https://winworldpc.com/product/pfs-professional-file/20)
- Quicken for DOS
- [Norton Utilities](http://symantec.com/norton/norton-utilities) for DOS
  - Norton Disk Doctor
  - Norton Speed Disk
- PC Tools
  - PC Shell
- Norton Ghost
- PKUnzip/Zip (pkz204g), Arc, Arj, etc
- Paragon Partition Manager for DOS
- Partition Magic

### Formerly-Used Browser Extensions

For comprehensive historical browser extension snapshots, see [docs/formerly-used-browser-extensions.md](docs/formerly-used-browser-extensions.md).

#### Safari Extensions

- [AdGuard for Safari](https://apps.apple.com/us/app/adguard-for-safari/id1440147259?mt=12&uo=4&at=10l4tL) ([Open-Source](https://github.com/AdguardTeam/AdguardForSafari)): Replaced with uBlock Origin Lite for more efficient ad blocking.
- [PiPer](https://apps.apple.com/us/app/piper/id1421915518?mt=12&uo=4&at=10l4tL) ([Open-Source](https://github.com/amarcu5/PiPer)): Picture-in-Picture for Safari. No longer needed.
- [Privacy Redirect](https://apps.apple.com/us/app/privacy-redirect/id1578144015?uo=4&at=10l4tL) ([Open-Source](https://github.com/smmr-software/privacy-redirect-safari)): No longer needed.
- [Refined GitHub](https://apps.apple.com/us/app/refined-github/id1519867270?mt=12&uo=4&at=10l4tL): GitHub interface improvements. Removed in favor of userscript.
- [SingleFile](https://apps.apple.com/us/app/singlefile/id1609752330?uo=4&at=10l4tL) ([Open-Source](https://github.com/gildas-lormeau/SingleFile)): Save a complete web page into a single HTML file. No longer needed.
- [Shut Up](https://apps.apple.com/us/app/shut-up-comment-blocker/id1015043880?uo=4&at=10l4tL): Comment blocker. No longer needed.
- [Social Fixer for Facebook](https://apps.apple.com/app/social-fixer-for-facebook/id1562017526): Replaced with userscript version.
- [Toolkit for YNAB](https://apps.apple.com/us/app/toolkit-for-ynab/id1592912837?mt=12&uo=4&at=10l4tL) ([Open-Source](https://github.com/toolkit-for-ynab/toolkit-for-ynab)): YNAB enhancements. No longer needed.
- [uBlacklist for Safari](https://apps.apple.com/us/app/ublacklist-for-safari/id1547912640?uo=4&at=10l4tL) ([Open-Source](https://github.com/HoneyLuka/uBlacklist/tree/safari-port/safari-project))
- [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887?uo=4&at=10l4tL) ([Open-Source](https://github.com/quoid/userscripts)): Temporarily replaced with Tampermonkey Classic while waiting for updates. Will switch back in the future.

### Intentionally Avoided Software

Software that I've used in the past but now actively avoid due to specific issues or problems.

- [Balena Etcher](https://www.balena.io/etcher/): USB/SD card imaging tool. Caused frequent corruption on SD cards, so I avoid it and use other tools like `dd`, Raspberry Pi Imager, or Rufus instead.

## Implementation Notes

- Chezmoi is used to apply my dotfiles changes.
- A script is run by chezmoi which applies my nix home-manager configuration, if nix is installed.
- .config/git/config is not my main configuration, but is instead a small file
  which includes my main configuration. This allows for automatic git
  configuration changes such as vscode's change to credential.manager to be
  obeyed without it altering my stored git configuration. The downside to this
  is that these changes will not be highly visible. I may change this back, or
  keep the including file but track it so the changes are visible.

## Reference

### Chezmoi Usage

- [Handle different file locations on different systems with the same contents](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/#handle-different-file-locations-on-different-systems-with-the-same-contents)
- [Use completely different dotfiles on different machines](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/#use-completely-different-dotfiles-on-different-machines)

## Supported Platforms

- Linux. Tested on Arch, Ubuntu, and Debian.
- MacOS.
- FreeBSD.
- Windows.

## Help

Questions and comments are always welcome, please open an issue.

## Contributing

Contributions of all kinds, including feedback, are always welcome!

See [CONTRIBUTING.md](CONTRIBUTING.md) for ways to get started.

Please adhere to this project's [Code of Conduct](CODE_OF_CONDUCT.md) and follow [The Ethical Source Principles](https://ethicalsource.dev/principles/).

## License

Distributed under the terms of the [Blue Oak Model License 1.0.0](LICENSE.md) license.

## See Also

### Superseded Projects

- [dotfiles-chezmoi](https://github.com/kergoth/dotfiles-chezmoi)
- [system-setup](https://github.com/kergoth/system-setup)
- [mac-setup](https://github.com/kergoth/mac-setup)
- [win-setup](https://github.com/kergoth/win-setup)
- [dotfiles/system-setup](https://github.com/kergoth/dotfiles/tree/d9bdcb2187ea66847a21ebd6591c0f1ec1a3f0a5/system-setup)
- [arch-setup](https://github.com/kergoth/kergoth-arch-setup)
