# Kergoth's Dotfiles and Setup Scripts

[![BlueOak 1.0.0 License](https://img.shields.io/badge/License-BlueOak%201.0.0-2D6B79.svg)](https://spdx.org/licenses/BlueOak-1.0.0.html)

This repository includes scripts for setting up systems per my personal
preferences.

## Prerequisites

- (On macOS) Command-Line Tools or XCode must be installed (See scripts/extras/ for scripts to install these).

## Usage

### Initial dotfiles setup

This setup will apply the dotfiles, and will also install packages with home-manager, if nix is installed.

If the repository has not yet been cloned:

```console
chezmoi init --apply kergoth/dotfiles
```

If the repository is already cloned and you've changed directory to it:

```console
./script/setup
```

### User Setup

This setup will apply the dotfiles, but will also apply other changes to the current user configuration.

After cloning the repository, and changing directory to it, run:

```console
./script/setup-user
```

On windows (in powershell, not WSL), run this instead:

```console
./script/setup-user.ps1
```

### System Setup

On Arch and FreeBSD, early setup scripts exist in ./script/arch and ./script/freebsd, respectively. These are
self-contained and may be used without cloning the repository:

- os-install: Currently I only have a single script for this, which is Arch.
  This is run as root, prior to rebooting into the newly installed system, and
  is intended to install and perform initial early system setup such as
  bootloader installation. This script is intended to be able to run without
  cloning this repository, so must be self-contained, and by definition is
  os/distro-specific, so exists in a subdirectory of script/ for each.
- setup-root: This is run as root, after OS installation, before our user has
  sudo/doas access, possibly before our user exists, and its purpose is to do
  just this, add our user and ensure it can use sudo or doas, and nothing more.
  This script is intended to be able to run without cloning this repository, so
  must be self-contained, and by definition is os/distro-specific, so exists in
  a subdirectory of script/ for each.

The setup-system script is run by a non-root user with sudo/doas access, to perform post-install system-level setup and configuration.
This script will apply changes to the system as a whole. This may include installing packages through the package manager, installing nix, et cetera. Ideally this should be run prior to setting up the user, and should be run as a user with sudo access.

After cloning the repository, and changing directory to it, run:

```console
./script/setup-system
```

On windows (in powershell, not WSL), run this instead:

```console
./script/setup-system.ps1
```

### Edit dotfiles

```console
chezmoi edit --watch ~/.config/zsh/.zshrc
```

### Apply dotfiles changes to the home directory

This step is implicitly done by the boostrap script. To run it manually, for example, after editing files inside the repository checkout, run this:

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

- Enable `secure keyboard entry` in Terminal
- `./scripts/extras/enable-filevault`
- System Settings > Lock Screen

  - Set “Require password after screen saver begins or display is turned off” to after 5 seconds or less.

- System Settings > Privacy & Security > Security

  - Set “Allow applications downloaded from App Store and identified developers” at most.

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

### Manual Setup Steps for Windows

- Set up all my Syncthing shares
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

#### External Scripts included for non-Windows platforms

- [bat-extras](https://github.com/eth-p/bat-extras): Scripts that integrate bat with various command line tools.
- [cht.sh](https://github.com/chubin/cheat.sh#command-line-client-chtsh): Command-line client for [cheat.sh](https://cheat.sh), the only cheat sheet you need.

### Fonts

- [iA-Fonts](https://github.com/iaolo/iA-Fonts): iA Writer Mono, Duo, and Quattro.
- [MesloLGS NF](https://github.com/romkatv/powerlevel10k/blob/master/font.md): Meslo Nerd Font patched for Powerlevel10k.

### Installed CLI Packages

- [curl](https://curl.se): Command line tool and library for transferring data with URLs.
- [wget](https://www.gnu.org/software/wget/): A free software package for retrieving files using HTTP, HTTPS, FTP and FTPS.
- [git](https://git-scm.com): A free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.
- [git-lfs](https://git-lfs.github.com): An open source Git extension for versioning large files.
- [neovim](https://neovim.io): Hyperextensible Vim-based text editor.
- [gnupg](https://www.gnupg.org): A complete and free implementation of the OpenPGP standard.

- [rust](https://www.rust-lang.org): A multi-paradigm, general-purpose programming language.
- [go](https://go.dev): An open source programming language supported by Google
- [python](https://www.python.org): A programming language that lets you work quickly and integrate systems more effectively.
- [pipx](https://pypi.org/project/pipx/): Install and run python applications in isolated environments.

- [bat](https://github.com/sharkdp/bat): A cat(1) clone with syntax highlighting and Git integration.
- [choose](https://github.com/theryangeary/choose): A human-friendly and fast alternative to cut and (sometimes) awk.
- [delta](https://github.com/dandavison/delta): A syntax-highlighting pager for git, diff, and grep output.
- [direnv](https://direnv.net): An extension for your shell which can load and unload environment variables depending on the current directory.
- [duf](https://github.com/muesli/duf): Disk Usage/Free Utility - a better 'df' alternative.
- [dua](https://github.com/Byron/dua-cli): View disk space usage and delete unwanted data, fast. This is a faster version of ncdu.
- [dust](https://github.com/bootandy/dust): A more intuitive version of du in rust.
- [eza](https://github.com/eza-community/eza) or [exa](https://github.com/ogham/exa): A modern replacement for ls.
- [fd](https://github.com/sharkdp/fd): A simple, fast and user-friendly alternative to 'find'.
- [fzf](https://github.com/junegunn/fzf): A command-line fuzzy finder.
- [ghq](https://github.com/x-motemen/ghq): Remote repository management made easy.
- [git-absorb](https://github.com/tummychow/git-absorb): git commit --fixup, but automatic.
- [git-branchless](https://github.com/arxanas/git-branchless): High-velocity, monorepo-scale workflow for Git.
- [git-imerge](https://github.com/mhagger/git-imerge): Incremental merge for git.
- [git-revise](https://github.com/mystor/git-revise): A handy tool for doing efficient in-memory commit rebases & fixups.
- [jira-cli](https://github.com/ankitpokhrel/jira-cli): Feature-rich interactive Jira command line.
- [jq](https://github.com/stedolan/jq): A lightweight and flexible command-line JSON processor.
- [ripgrep](https://github.com/BurntSushi/ripgrep): A line-oriented search tool that recursively searches the current directory for a regex pattern.
- [sad](https://github.com/ms-jpq/sad): CLI search and replace | Space Age seD.
- [sd](https://github.com/chmln/sd): Intuitive find & replace CLI (sed alternative).
- [shellcheck](https://github.com/koalaman/shellcheck): A static analysis tool for shell scripts.
- [shfmt](https://github.com/mvdan/sh#shfmt): Format shell programs.
- [tealdeer](https://github.com/dbrgn/tealdeer): Simplified, example based and community-driven man pages.
- [unar](https://theunarchiver.com/command-line): Universal archives extractor. Available via brew, nix, and scoop.
- [zoxide](https://github.com/ajeetdsouza/zoxide): A smarter cd command, inspired by z and autojump.
- [zstd](http://www.zstd.net/): Zstandard - Fast real-time compression algorithm.

#### CLI Packages on Linux and macOS

- [nix](https://nixos.org): Nix is a tool that takes a unique approach to package management and system configuration.

#### CLI Packages on Linux, macOS, and FreeBSD

- [patchutils](http://cyberelk.net/tim/software/patchutils/): A small collection of programs that operate on patch files.

  - On Windows, patchutils can be used via either WSL or MSYS2 (which can be installed via scoop and run as `msys2`, ex. `msys2 -c 'exec filterdiff "$@"' -`).

- [ssh-copy-id](https://www.openssh.com): Install your identity.pub in a remote machine’s authorized_keys.

  - On Windows, I have a powershell function which does this, and is aliased to `ssh-copy-id`.

- [tmux](https://github.com/tmux/tmux): An open-source terminal multiplexer.

  - There are no good options for tmux or tmux-equivalent on Windows. The closest you can get is just splits in Windows Terminal, which doesn't give you the ability to disconnect.

#### CLI Packages on Linux, macOS, and Windows

- [sapling](https://sapling-scm.com): A Scalable, User-Friendly Source Control System.

#### CLI Packages on macOS

- [lima](https://github.com/lima-vm/lima): Linux virtual machines, typically on macOS, for running containerd.
- [colima](https://github.com/abiosoft/colima): Container runtimes on macOS (and Linux) with minimal setup.
- [duti](https://github.com/moretension/duti): A command-line tool to select default applications for document types and URL schemes on Mac OS X.
- [mas](https://github.com/mas-cli/mas): Mac App Store command line interface.
- [reattach-to-user-namespace](https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard): Reattach to the per-user bootstrap namespace. This is needed for tools like tmux, though tmux 2.6+ apparently incorporates this functionality already.
- [trash](https://hasseg.org/trash/): A small command-line program for OS X that moves files or folders to the trash.

#### CLI Packages on Linux and FreeBSD

The intention is to incorporate the installation of Nix on all systems in time.

- [zsh](https://zsh.sourceforge.io): A shell designed for interactive use, although it is also a powerful scripting language. This is installed by default on macOS.

##### CLI Packages on Arch Linux

- [openssh](https://www.openssh.com): The premier connectivity tool for remote login with the SSH protocol.
- [avahi](https://avahi.org): A system which facilitates service discovery on a local network via mDNS.
- [nss-mdns](http://0pointer.de/lennart/projects/nss-mdns/): A GNU Libc NSS module that provides mDNS host name resolution.

##### CLI Packages on WSL2

- [socat](http://www.dest-unreach.org/socat/): Multipurpose relay for bidirectional data transfer. This is required for [npiperelay](https://github.com/jstarks/npiperelay).

#### CLI Packages on Windows

- [bat-extras](https://github.com/eth-p/bat-extras): Scripts that integrate bat with various command line tools.
- [Build Tools for Visual Studio 2022](https://visualstudio.microsoft.com/downloads/): These Build Tools allow you to build Visual Studio projects from a command-line interface.
- [cht.exe](https://github.com/tpanj/cht.exe): cht.sh libcurl client for Windows.
- [gow](https://github.com/bmatzelle/gow): Unix command line utilities installer for Windows.
- [npiperelay](https://github.com/jstarks/npiperelay): Access Windows named pipes from WSL.
- [scoop](https://scoop.sh): A command-line installer for Windows.
- [starship](https://starship.rs): A cross-shell prompt.
- [winget](https://github.com/microsoft/winget-cli): Windows Package Manager CLI.

#### Powershell Modules

- [DirColors](https://www.powershellgallery.com/packages/DirColors): Provides dircolors-like functionality to all System.IO.FilesystemInfo formatters.
- [posh-alias](https://www.powershellgallery.com/packages/posh-alias): A better alias for Powershell.
- [PSFzf](https://github.com/kelleyma49/PSFzf): A PowerShell wrapper around the fuzzy finder fzf.
- [Recycle](https://www.powershellgallery.com/packages/Recycle): Deletes the file or folder as if it had been done via File Explorer, or restores a deleted file from the recycle bin.

#### Powershell Modules on Windows only

- [Microsoft.WinGet.Client](https://www.powershellgallery.com/packages/Microsoft.WinGet.Client): PowerShell Module for the Windows Package Manager Client.

### Installed GUI Software (MacOS & Windows Only)

#### GUI Software on Windows and macOS

- [1Password](https://1password.com): A password manager developed by AgileBits.
- [Discord](https://discord.com): A VoIP and instant messaging social platform.
- [IRCCloud](https://www.irccloud.com/): IRC client.
- [Microsoft Teams](https://www.microsoft.com/en/microsoft-teams/group-chat-software/): Meet, chat, call, and collaborate in just one place.
- [Visual Studio Code](https://code.visualstudio.com): Open-source code editor.
- [Vivaldi](https://vivaldi.com/): Web browser with built-in email client focusing on customization and control.
- [VLC](https://www.videolan.org/vlc/download-macosx.html): A free and open source cross-platform multimedia player.

#### GUI Software on macOS (Pre-Sonoma Only)

- [Aerial](https://aerialscreensaver.github.io): A macOS screensaver that lets you play videos from Apple's tvOS screensaver.

#### GUI Software on macOS

- [Alfred](https://www.alfredapp.com): Application uninstaller.
- [AppCleaner](https://freemacsoft.net/appcleaner/): A small application which allows you to thoroughly uninstall unwanted apps.
- [BlockBlock](https://objective-see.org/products/blockblock.html): Monitors common persistence locations and alerts whenever a persistent component is added.
- [Brooklyn](https://github.com/pedrommcarrasco/Brooklyn): Screen saver based on animations presented during Apple Special Event Brooklyn.
- [Calibre](https://calibre-ebook.com): E-books management software.
- [CleanMyDrive 2](https://apps.apple.com/us/app/cleanmydrive-2/id523620159?mt=12&uo=4&at=10l4tL)
- [DaisyDisk](https://daisydiskapp.com): Disk space visualizer. Get a visual breakdown of your disk space in form of an interactive map, reveal the biggest space wasters, and remove them with a simple drag and drop.
- [DevDocs for macOS](https://github.com/dteoh/devdocs-macos): An unofficial [DevDocs API Documentation](https://devdocs.io/) viewer for macOS.
- [GPG Suite](https://gpgtools.org): Tools to protect your emails and files.
- [GoodLinks](https://apps.apple.com/us/app/goodlinks/id1474335294?uo=4&at=10l4tL): Save links, read later.
- [Hidden Bar](https://apps.apple.com/us/app/hidden-bar/id1452453066?mt=12&uo=4&at=10l4tL): Hide menubar items.
- [Itsycal for Mac](https://www.mowglii.com/itsycal/): A tiny menu bar calendar.
- [Karabiner-Elements](https://karabiner-elements.pqrs.org): A powerful and stable keyboard customizer for macOS.
- [kitty](https://sw.kovidgoyal.net/kitty/): The fast, feature-rich, GPU based terminal emulator.
- [LilyView](https://apps.apple.com/us/app/lilyview/id529490330?mt=12&uo=4&at=10l4tL)
- [LuLu](https://objective-see.org/products/lulu.html): The free, open-source firewall that aims to block unknown outgoing connections.
- [MusicHarbor](https://apps.apple.com/us/app/musicharbor-track-new-music/id1440405750?uo=4&at=10l4tL)
- [PopClip](https://apps.apple.com/us/app/popclip/id445189367?mt=12&uo=4&at=10l4tL): Instant text actions.
- [Rectangle](https://rectangleapp.com): Move and resize windows in macOS using keyboard shortcuts or snap areas.
- [SwiftDefaultApps](https://github.com/Lord-Kamina/SwiftDefaultApps): A preference pane will let you view and change default application associations.
- [SyncThing](https://syncthing.net/): A continuous file synchronization program.
- [The Unarchiver](https://macpaw.com/download/the-unarchiver): Unpack archive files.
- [Transmission Remote GUI](https://github.com/transmission-remote-gui/transgui): A feature rich cross platform Transmission BitTorrent client. Faster and has more functionality than the built-in web GUI.
- [UnPlugged](https://apps.apple.com/us/app/unplugged/id423123087?mt=12&uo=4&at=10l4tL)
- [WhatsYourSign](https://objective-see.org/products/whatsyoursign.html): Add a menu item to Finder to display a file's cryptographic information.
- [WiFi Explorer](https://apps.apple.com/us/app/wifi-explorer/id494803304?mt=12&uo=4&at=10l4tL): Best Wi-Fi Analyzer & Monitor.
- [WiFi Signal](https://apps.apple.com/us/app/wifi-signal-status-monitor/id525912054?mt=12&uo=4&at=10l4tL): WiFi Connection Status Monitor.

##### Safari Extensions

- [1Password for Safari](https://apps.apple.com/us/app/1password-for-safari/id1569813296?mt=12&uo=4&at=10l4tL)
- [AdGuard for Safari](https://apps.apple.com/us/app/adguard-for-safari/id1440147259?mt=12&uo=4&at=10l4tL)
- [Hush](https://apps.apple.com/us/app/hush-nag-blocker/id1544743900?uo=4&at=10l4tL)
- [PiPer](https://apps.apple.com/us/app/piper/id1421915518?mt=12&uo=4&at=10l4tL)
- [Privacy Redirect](https://apps.apple.com/us/app/privacy-redirect/id1578144015?uo=4&at=10l4tL)
- [Social Fixer for Facebook](https://apps.apple.com/app/social-fixer-for-facebook/id1562017526)
- [SessionRestore](https://apps.apple.com/us/app/sessionrestore-for-safari/id1463334954?mt=12&uo=4&at=10l4tL)
- [Shut Up](https://apps.apple.com/us/app/shut-up-comment-blocker/id1015043880?uo=4&at=10l4tL)
- [StopTheMadness](https://apps.apple.com/us/app/stopthemadness/id1376402589?mt=12&uo=4&at=10l4tL)
- [Tampermonkey](https://www.onlinedown.net/soft/1229995.htm)
- [Toolkit for YNAB](https://apps.apple.com/us/app/toolkit-for-ynab/id1592912837?mt=12&uo=4&at=10l4tL)
- [uBlacklist for Safari](https://apps.apple.com/us/app/ublacklist-for-safari/id1547912640?uo=4&at=10l4tL)
- [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887?uo=4&at=10l4tL)
- [Vinegar](https://apps.apple.com/us/app/vinegar-tube-cleaner/id1591303229?uo=4&at=10l4tL)

##### QuickLook Plugins

- [Apparency](https://www.mothersruin.com/software/Apparency/): Preview the contents of a macOS app
- [BetterZip](https://betterzip.com): A trialware file archiver. I only install this for the QuickLook plugin.
- [QLColorCode](https://github.com/anthonygelibert/QLColorCode): A Quick Look plug-in that renders source code with syntax highlighting
- [qlImageSize](https://github.com/Nyx0uf/qlImageSize): Display image size and resolution
- [QLMarkDown](https://github.com/toland/qlmarkdown): Preview Markdown files
- [QLPrettyPatch](https://github.com/atnan/QLPrettyPatch): QuickLook generator for patch files
- [QLStephen](https://github.com/whomwah/qlstephen): Preview plain text files without or with unknown file extension. Example: README, CHANGELOG, index.styl, etc
- [QLVideo](https://github.com/Marginal/QLVideo): Preview most types of video files, as well as their thumbnails, cover art and metadata
- [quicklook-csv](https://github.com/p2/quicklook-csv): A QuickLook plugin for CSV files
- [QuickLookJSON](http://www.sagtau.com/quicklookjson.html): A useful quick look plugin to preview JSON files
- [QuickLookASE](https://github.com/rsodre/QuickLookASE): Preview Adobe ASE Color Swatches generated with Adobe Photoshop, Adobe Illustrator, Adobe Color CC, Spectrum, COLOURlovers, Prisma, among many others
- [Suspicious Package](https://www.mothersruin.com/software/SuspiciousPackage/): Preview the contents of a standard Apple installer package
- [WebPQuickLook](https://github.com/emin/WebPQuickLook): QuickLook plugin for WebP image files

#### GUI Software on Windows

- [7-Zip](https://www.7-zip.org/)
- [AutoHotkey](https://www.autohotkey.com/)
- [Bulk Crap Uninstaller](https://www.bcuninstaller.com): Remove large amounts of unwanted applications quickly.
- [DevDocs Desktop](https://github.com/egoist/devdocs-desktop): A full-featured desktop app for DevDocs.io.
- [Ditto](https://ditto-cp.sourceforge.io)
- [Gpg4win](https://www.gpg4win.org): Secure email and file encryption with GnuPG for Windows.
- [Notepad++](https://notepad-plus-plus.org/)
- [PowerShell](https://learn.microsoft.com/en-us/powershell/)
- [PowerToys](https://learn.microsoft.com/en-us/windows/powertoys/)
- [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/)
- [QuickLook](https://github.com/QL-Win/QuickLook)
- [Rufus](https://rufus.ie/)
- [SnipDo](https://snipdo-app.com): Select a text in any application and SnipDo pops up to help you.
- [SyncTrayzor](https://github.com/canton7/SyncTrayzor)
- [WiFi Analyzer](https://apps.microsoft.com/detail/9NBLGGH33N0N?hl=en-US&gl=US): Identify Wi-Fi problems or find the best channel.
- [Windows Firewall Control](https://www.binisoft.org/wfc): Managing Windows Firewall is now easier than ever.
- [Windows Terminal](https://apps.microsoft.com/store/detail/9N0DX20HK701?hl=en-us&gl=US)
- [WizTree](https://diskanalyzer.com): View the size of all files and folders visually.

## Apps I install on an as-needed basis

### As needed CLI Packages

- [asciinema](https://asciinema.org/)]: Recording terminal sessions and sharing them on the web. Available via brew, nix, and python.
- [aria2](https://github.com/aria2/aria2): A lightweight multi-protocol & multi-source, cross platform download utility operated in command-line. It supports HTTP/HTTPS, FTP, SFTP, BitTorrent and Metalink. Available via brew, nix, and scoop.
- [broot](https://github.com/Canop/broot): A new way to see and navigate directory trees. Available via brew, nix, scoop, and cargo.
- [chars](https://github.com/antifuchs/chars). Tool to display names and codes for unicode codepoints. Available via brew, nix, and cargo.
- [csview](https://github.com/wfxr/csview): 📠 Pretty and fast csv viewer for cli with cjk/emoji support. Available via brew, nix, scoop, and cargo.
- [csvkit](https://github.com/wireservice/csvkit): A suite of utilities for converting to and working with CSV. Available via brew, nix, and python.
- [dasel](https://github.com/TomWright/dasel): Select, put and delete data from JSON, TOML, YAML, XML and CSV files with a single tool. Available via brew, nix, scoop, and go.
- [dirdiff](https://github.com/OCamlPro/dirdiff): Efficiently compute the differences between two directories. Available via cargo as `dirdiff-ocamlpro`.
- [dog](https://github.com/ogham/dog): A command-line DNS client. Available via brew as `dog`, nix as `dogdns`, and cargo from the source.
- [entr](https://github.com/eradman/entr): Run arbitrary commands when files change. Available via brew and nix.
- [eva](https://github.com/nerdypepper/eva): A simple calculator REPL, similar to bc. Available via brew, nix, and cargo.
- [fast](https://github.com/ddo/fast): Minimal zero-dependency utility for testing your internet download speed from terminal. Available via nix as `fast-cli` and go.
- [fclones](https://github.com/pkolaczk/fclones): Finds and removes duplicate files. Available via brew, nix, and cargo.
- [ffmpeg](https://ffmpeg.org): A complete, cross-platform solution to record, convert and stream audio and video. Available via brew, nix, and scoop.
- [flint](https://github.com/pengwynn/flint): Check your project for common sources of contributor friction. Available via brew as `flint-checker` and go.
- [git-filter-repo](https://github.com/newren/git-filter-repo): Quickly rewrite git repository history (filter-branch replacement).
- [hexyl](https://github.com/sharkdp/hexyl): A simple hex viewer for the terminal. Available via brew, nix, and cargo.
- [htop](https://htop.dev): An interactive process viewer. Available via brew and nix.
- [httpie](https://github.com/httpie/httpie): A command-line HTTP client. Available via brew, nix, and python.
- [huniq](https://github.com/koraa/huniq): Command line utility to remove duplicates from the given input. Available via nix and cargo. Uses less memory than awk/uniq-seen. Rarely needed.
- [hyperfine](https://github.com/sharkdp/hyperfine): A command-line benchmarking tool. Available via brew, nix, and cargo.
- [jc](https://github.com/kellyjonbrazil/jc): CLI tool and python library that converts the output of popular command-line tools, file-types, and common strings to JSON, YAML, or Dictionaries. Available via brew, nix, scoop, and pypi.
- [petname](https://github.com/dustinkirkland/petname): Generate human readable random names. Available via pypi and cargo.
- [procs](https://github.com/dalance/procs): A modern replacement for ps written in Rust. Available via brew, nix, scoop, and cargo.
- [pup](https://github.com/ericchiang/pup): A command line tool for processing HTML. Available via brew, nix, and go.
- [rclone](https://github.com/rclone/rclone): Rsync for cloud storage. Available via brew, nix, and scoop.
- [titlecase](https://github.com/wezm/titlecase): A small tool that capitalizes English text. Available via cargo.
- [vivid](https://github.com/sharkdp/vivid): A generator for the LS_COLORS environment variable. Available via brew, nix, and cargo.
- [youtube-dl](https://youtube-dl.org): Video downloading. Available via brew, nix, and python.

#### On my NAS, to download what I own

- [lgogdownloader](https://github.com/Sude-/lgogdownloader): Unofficial downloader for GOG.com. Available via brew and nix.

#### To deal with icons and images

- [icoutils](https://www.nongnu.org/icoutils/): A set of command-line programs for extracting and converting images in Microsoft Windows(R) icon and cursor files. Available via brew and nix.
- [imagemagick](https://imagemagick.org): Create, edit, compose, or convert digital images. Available via brew, nix, and scoop.

#### For [beets](https://beets.io)

- [mp3val](https://mp3val.sourceforge.net): A small, high-speed, free software tool for checking MPEG audio files' integrity. Available via brew and nix. Also available as direct binary download for Windows.
- [par2cmdline](https://github.com/Parchive/par2cmdline): Available via brew as `par2`, nix, and scoop.

#### As Needed CLI Packages for macOS

- [makeicns](http://www.amnoid.de/icns/makeicns.html): Create icns files from the command line. Available via brew.
- [terminal-notifier](https://github.com/julienXX/terminal-notifier): A command-line tool to send macOS User Notifications. Available via brew and nix.

### As Needed GUI Software

- [Balena Etcher](https://www.balena.io/etcher/): Flash OS images to SD cards & USB drives, safely and easily. Available via brew as `balenaetcher`, winget as `Balena.Etcher`, and scoop as `extras/etcher`.
- [Battle.net](https://us.shop.battle.net/en-us?from=root): Blizzard games client. Available via brew as `battle-net`.
- [czkawka](https://github.com/qarmin/czkawka): Multi functional app to find duplicates, empty folders, similar images etc.
- [dupeGuru](https://dupeguru.voltaicideas.net): A cross-platform GUI tool to find duplicate files in a system.
- [HandBrake](https://handbrake.fr/): The open source video transcoder. Available via brew as `handbrake` and winget as `HandBrake.HandBrake`.
- [Malwarebytes](https://www.malwarebytes.com): Warns about malware, adware and spyware.
- [MusicBrainz Picard](https://picard.musicbrainz.org): A cross-platform music tagger. Available via brew as `musicbrainz-picard`, nix as `picard`, Microsoft Store, winget as `MusicBrainz.Picard`, and scoop as `picard`.
- [Steam](https://store.steampowered.com): A digital distribution platform. Available via brew, nix, and winget as `Valve.Steam`.
- [Video Duplicate Finder](https://github.com/0x90d/videoduplicatefinder): Cross-platform software to find duplicated video (and image) files on hard disk based on similiarity.

#### As Needed GUI Software for macOS

- [Adapter](https://macroplant.com/adapter): Convert Video, Audio and Images. Available via brew as `adapter`.
- [Burn](https://burn-osx.sourceforge.io/Pages/English/home.html): Simple but advanced burning for Mac OS X. Optional, as disk images can be burned with Finder or hdiutil. Available via brew as `burn`.
- [Gemini 2](https://macpaw.com/gemini): The intelligent duplicate file finder. Available via brew as `gemini`.
- [KnockKnock](https://objective-see.org/products/knockknock.html): See what's persistently installed on your Mac.
- [Numbers](https://www.apple.com/numbers/): Create impressive spreadsheets. Available via Mac App Store.
- [Onyx](https://www.titanium-software.fr/en/onyx.html): Verify system files structure, run miscellaneous maintenance and more. Available via brew as `onyx`.
- [Pages](https://www.apple.com/pages/): Documents that stand apart. Available via Mac App Store.
- [PhotoSweeper](https://overmacs.com): A fast & powerful duplicate photos cleaner for Mac. Available via brew as `photosweeper-x`.
- [Pixelmator Classic](https://www.pixelmator.com/mac/): Powerful, full-featured image editor for Mac. Available via Mac App Store.
- [SwiftBar](https://swiftbar.app/)]: Powerful macOS menu bar customization tool.
- [TaskExplorer](https://objective-see.org/products/taskexplorer.html): Explore all the tasks (processes) running on your Mac with TaskExplorer.
- [Wineskin](https://github.com/Gcenx/WineskinServer): A user-friendly tool used to make ports of Microsoft Windows software to macOS. Available via brew as `gcenx/wine/unofficial-wineskin`.
- [XLD](https://tmkk.undo.jp/xld/index_e.html): Lossless audio decoder.

#### As Needed GUI Software for Windows (All are available via winget)

- [Autoruns](https://learn.microsoft.com/en-us/sysinternals/downloads/autoruns) (from [Sysinternals](https://learn.microsoft.com/en-us/sysinternals/))
- [BleachBit](https://www.bleachbit.org): Clean Your System and Free Disk Space. Available via winget as `BleachBit.BleachBit`.
- [Exact Audio Copy](https://www.exactaudiocopy.de): Audio grabber for audio CDs using standard CD and DVD-ROM drives
- [ImDisk](https://sourceforge.net/projects/imdisk-toolkit/): Mount image files of hard drive, cd-rom or floppy.
- [ImgBurn](https://www.imgburn.com): A lightweight CD / DVD / HD DVD / Blu-ray burning application. Available via winget as `LIGHTNINGUK.ImgBurn`.
- [Paint.NET](https://getpaint.net)
- [Process Explorer](https://learn.microsoft.com/en-us/sysinternals/downloads/process-explorer) (from [Sysinternals](https://learn.microsoft.com/en-us/sysinternals/))
- [WinImage](https://www.winimage.com/winimage.htm): A fully-fledged disk-imaging suite for easy creation, reading and editing of many image formats and fileystems.
- [WinSCP](https://winscp.net/)

## Formerly-Used

### Formerly-Used Applications

- [ACDSee](https://en.wikipedia.org/wiki/ACDSee). Loved this as an ultralight image viewer in the past, but it grew bloated over time, so was replaced by Irfan View or XnView, as needed.
- [foobar2000](https://www.foobar2000.org): This is a great music player, but I use Apple Music and iTunes for streaming, and beets for my music library for portable devices, so this is no longer needed.
- [Winamp](https://en.wikipedia.org/wiki/Winamp): This was the way before I switched to foobar2000 long ago.

### Formerly-Used Fonts

- [Recursive](https://www.recursive.design) Code
- [Fira Code](https://github.com/tonsky/FiraCode)
- [Input](https://input.djr.com) Mono Narrow
- [Inconsolata](https://levien.com/type/myfonts/inconsolata.html): See also [Google Fonts](https://fonts.google.com/specimen/Inconsolata)
- [Terminus](https://terminus-font.sourceforge.net)
- [DejaVu](https://dejavu-fonts.github.io) Sans Mono
- [Leonine Sans Mono](https://www.leonerd.org.uk/hacks/hints/leoninesansmono.html)
- [Bitstream Vera](https://web.archive.org/web/20210314185159/https://www.gnome.org/fonts/) Sans Mono: See [download](https://download.gnome.org/sources/ttf-bitstream-vera/1.10/)

### Formerly-Used Fonts - Occasional Use

- [Envy Code R](https://damieng.com/blog/2008/05/26/envy-code-r-preview-7-coding-font-released)

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

### Mostly Superseded Projects

- [arch-setup](https://github.com/kergoth/kergoth-arch-setup)
