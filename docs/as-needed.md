# As-Needed Software

Software I install occasionally as needed rather than on every machine. See the main [README](../README.md) for what's installed by default.

## As needed CLI Software

- **[asciinema](https://asciinema.org/)**]: Recording terminal sessions and sharing them on the web. Available via brew, nix, and python.
- **[aria2](https://github.com/aria2/aria2)**: A lightweight multi-protocol & multi-source, cross platform download utility operated in command-line. It supports HTTP/HTTPS, FTP, SFTP, BitTorrent and Metalink. Available via brew, nix, and scoop.
- **[broot](https://github.com/Canop/broot)**: A new way to see and navigate directory trees. Available via brew, nix, scoop, and cargo.
- **[chars](https://github.com/antifuchs/chars)**. Tool to display names and codes for unicode codepoints. Available via brew, nix, and cargo.
- **[csview](https://github.com/wfxr/csview)**: 📠 Pretty and fast csv viewer for cli with cjk/emoji support. Available via brew, nix, scoop, and cargo.
- **[csvkit](https://github.com/wireservice/csvkit)**: A suite of utilities for converting to and working with CSV. Available via brew, nix, and python.
- **[dasel](https://github.com/TomWright/dasel)**: Select, put and delete data from JSON, TOML, YAML, XML and CSV files with a single tool. Available via brew, nix, scoop, and go.
- **[dirdiff](https://github.com/OCamlPro/dirdiff)**: Efficiently compute the differences between two directories. Available via cargo as `dirdiff-ocamlpro`.
- **[dog](https://github.com/ogham/dog)**: A command-line DNS client. Available via brew as `dog`, nix as `dogdns`, and cargo from the source.
- **[doxx](https://github.com/bgreenwell/doxx)**: Expose the contents of .docx files without leaving your terminal. Available via cargo from the source.
- **[entr](https://github.com/eradman/entr)**: Run arbitrary commands when files change. Available via brew and nix.
- **[eva](https://github.com/nerdypepper/eva)**: A simple calculator REPL, similar to bc. Available via brew, nix, and cargo.
- **[fast](https://github.com/ddo/fast)**: Minimal zero-dependency utility for testing your internet download speed from terminal. Available via nix as `fast-cli` and go.
- **[ffmpeg](https://ffmpeg.org)**: A complete, cross-platform solution to record, convert and stream audio and video. Available via brew, nix, and scoop.
- **[flint](https://github.com/pengwynn/flint)**: Check your project for common sources of contributor friction. Available via brew as `flint-checker` and go.
- **[git-filter-repo](https://github.com/newren/git-filter-repo)**: Quickly rewrite git repository history (filter-branch replacement).
- **[glab](https://gitlab.com/gitlab-org/cli)**: A GitLab CLI tool bringing GitLab to your command line. Available via system packages (Arch: `glab`, FreeBSD: `glab`), Nix, Homebrew, MacPorts, scoop, winget (`GLab.GLab`), and eget.
- **[go](https://go.dev)**: An open source programming language supported by Google
- **[hexyl](https://github.com/sharkdp/hexyl)**: A simple hex viewer for the terminal. Available via brew, nix, and cargo.
- **[htop](https://htop.dev)**: An interactive process viewer. Available via brew and nix.
- **[httpie](https://github.com/httpie/httpie)**: A command-line HTTP client. Available via brew, nix, and python.
- **[huniq](https://github.com/koraa/huniq)**: Command line utility to remove duplicates from the given input. Available via nix and cargo. Uses less memory than awk/uniq-seen. Rarely needed.
- **[hyperfine](https://github.com/sharkdp/hyperfine)**: A command-line benchmarking tool. Available via brew, nix, and cargo.
- **[jc](https://github.com/kellyjonbrazil/jc)**: CLI tool and python library that converts the output of popular command-line tools, file-types, and common strings to JSON, YAML, or Dictionaries. Available via brew, nix, scoop, and pypi.
- **[petname](https://github.com/dustinkirkland/petname)**: Generate human readable random names. Available via pypi and cargo.
- **[procs](https://github.com/dalance/procs)**: A modern replacement for ps written in Rust. Available via brew, nix, scoop, and cargo.
- **[pup](https://github.com/ericchiang/pup)**: A command line tool for processing HTML. Available via brew, nix, and go.
- **[qemu](https://www.qemu.org)**: A generic and open source machine emulator and virtualizer. Available via brew, nix, scoop, FreeBSD Ports, winget (as SoftwareFreedomConservancy.QEMU), apk on chimera linux.
- **[rclone](https://github.com/rclone/rclone)**: Rsync for cloud storage. Available via brew, nix, and scoop.
- **[rust](https://www.rust-lang.org)**: A multi-paradigm, general-purpose programming language.
- **[titlecase](https://github.com/wezm/titlecase)**: A small tool that capitalizes English text. Available via cargo.
- **[vivid](https://github.com/sharkdp/vivid)**: A generator for the LS_COLORS environment variable. Available via brew, nix, and cargo.
- **[yt-dlp](https://github.com/yt-dlp/yt-dlp)**: A feature-rich command-line audio/video downloader. Available via brew, nix, scoop, winget, pacman, FreeBSD ports, pip/uv, and release binaries. Often requires `ffmpeg` and `deno` binaries.
  - The release binary can quickly be installed with eget: `eget --upgrade-only --asset='^zip' --to=~/.local/bin/yt-dlp yt-dlp/yt-dlp`

### On my NAS, to download what I own

- **[lgogdownloader](https://github.com/Sude-/lgogdownloader)**: Unofficial downloader for GOG.com. Available via brew and nix.

### To deal with icons and images

- **[icoutils](https://www.nongnu.org/icoutils/)**: A set of command-line programs for extracting and converting images in Microsoft Windows(R) icon and cursor files. Available via brew and nix.
- **[imagemagick](https://imagemagick.org)**: Create, edit, compose, or convert digital images. Available via brew, nix, and scoop.

### For [beets](https://beets.io)

- **[mp3val](https://mp3val.sourceforge.net)**: A small, high-speed, free software tool for checking MPEG audio files' integrity. Available via brew and nix. Also available as direct binary download for Windows.
- **[par2cmdline](https://github.com/Parchive/par2cmdline)**: Available via brew as `par2`, nix, and scoop.

### As Needed CLI Software for macOS

- **[makeicns](http://www.amnoid.de/icns/makeicns.html)**: Create icns files from the command line. Available via brew.
- **[Mole](https://github.com/tw93/Mole)**: All-in-one macOS system optimization tool for cleanup, uninstalling apps, disk analysis, and system monitoring. Available via brew as `mole`.
- **[mist-cli](https://github.com/ninxsoft/mist-cli)**: Mac command-line tool that automatically downloads macOS Firmwares / Installers. Available via brew.
- **[terminal-notifier](https://github.com/julienXX/terminal-notifier)**: A command-line tool to send macOS User Notifications. Available via brew and nix.

### As Needed CLI Software for Windows

- **[Build Tools for Visual Studio 2022](https://visualstudio.microsoft.com/downloads/)**: These Build Tools allow you to build Visual Studio projects from a command-line interface.

## As Needed GUI Software

- **[86Box](https://86box.net/)**: Emulator for vintage IBM PC and compatibles. Available via brew as `86box` and direct download.
- **[Battle.net](https://us.shop.battle.net/en-us?from=root)**: Blizzard games client. Available via brew as `battle-net`.
- **[CPDT (Cross Platform Disk Test)](https://www.magesw.com/cpdt/)**: A disk benchmarking tool for Windows, macOS, and Linux. Available via direct download.
- **[czkawka](https://github.com/qarmin/czkawka)**: Multi functional app to find duplicates, empty folders, similar images etc.
- **[dupeGuru](https://dupeguru.voltaicideas.net)**: A cross-platform GUI tool to find duplicate files in a system.
- **[Eddie](https://eddie.website/)** ([Open-Source](https://github.com/AirVPN/Eddie)): VPN client for AirVPN with OpenVPN and WireGuard support. Available via brew as `eddie` and winget as `AirVPN.Eddie`.
- **[HandBrake](https://handbrake.fr/)**: The open source video transcoder. Available via brew as `handbrake` and winget as `HandBrake.HandBrake`.
- **[jDownloader](https://jdownloader.org)**: A download management tool. Available via brew as `jdownloader`.
- **[Kegworks](https://github.com/Kegworks-App/Kegworks)**: A user-friendly tool used to make wine wrapped ports of Windows software for macOS. Formerly Wineskin Winery.
- **[LocalSend](https://localsend.org)**: Share files to nearby devices. Available via brew as `localsend`, winget as `LocalSend.LocalSend`, and scoop as `localsend`.
- **[Malwarebytes](https://www.malwarebytes.com)**: Warns about malware, adware and spyware.
- **[Ollama](https://ollama.com)**: Get up and running with large language models locally. Available via brew as `ollama`.
- **[Steam](https://store.steampowered.com)**: A digital distribution platform. Available via brew, nix, and winget as `Valve.Steam`.
- **[Subler](https://subler.org)**: A macOS app to mux and tag mp4 files. Available via brew as `subler`.
- **[SyncTERM](https://syncterm.bbsdev.net/)**: BBS terminal program. Available via brew as `syncterm` and direct download for Windows.
- **[Transmission](https://transmissionbt.com)**: A Fast, Easy and Free Bittorrent Client for macOS, Windows and Linux.
- **[Video Duplicate Finder](https://github.com/0x90d/videoduplicatefinder)**: Cross-platform software to find duplicated video (and image) files on hard disk based on similiarity.

### As Needed GUI Software for Windows and macOS

- **[SD Card Formatter](https://www.sdcard.org/downloads/formatter/)**: Official SD Memory Card Formatter from the SD Association for formatting SD/SDHC/SDXC cards.

### As Needed GUI Software for macOS

- **[Adapter](https://macroplant.com/adapter)**: Convert Video, Audio and Images. Available via brew as `adapter`.
- **[Mist](https://github.com/ninxsoft/Mist)**: Utility that automatically downloads macOS firmwares and installers. Available via brew as `mist` (cask).
- **[AmorphousDiskMark](https://katsurashareware.com/amorphousdiskmark/)**: Disk benchmark utility. Available via brew as `amorphousdiskmark`.
- **[AnyToISO](https://www.crystalidea.com/anytoiso)**: Convert CD/DVD images to ISO format or extract files from them. Available via brew as `anytoiso`.
- **[Apple Configurator](https://support.apple.com/apple-configurator)**: Configure and deploy iPhone, iPad, and Apple TV. Available via Mac App Store.
- **[Audio Overload](https://www.bannister.org/software/ao.htm)**: Emulator for retro video game music. Available via Mac App Store (via mas as id `1512000244`).
- **[Blackmagic Disk Speed Test](https://apps.apple.com/us/app/blackmagic-disk-speed-test/id425264550)**: Test your disk performance. Available via Mac App Store.
- **[Burn](https://burn-osx.sourceforge.io/Pages/English/home.html)**: Simple but advanced burning for Mac OS X. Optional, as disk images can be burned with Finder or hdiutil. Available via brew as `burn`.
- **[Byword](https://bywordapp.com)**: Markdown editor. Available via Mac App Store.
- **[DeltaPatcher](https://github.com/marco-calautti/DeltaPatcher)**: GUI and CLI application for creating and applying BPS, IPS, UPS, and xdelta3 binary patches. Available via brew as `deltapatcher`.
- **[Exporter](https://apps.apple.com/us/app/exporter/id1099120373)**: Export Apple Notes to various formats. Available via Mac App Store.
- **[Fluid](https://fluidapp.com)**: Turn Your Favorite Web Apps into Real Mac Apps. Available via brew as `fluid`.
- **[Gemini 2](https://macpaw.com/gemini)**: The intelligent duplicate file finder. Available via brew as `gemini`.
- **[Kindle](https://www.amazon.com/kindle-dbs/fd/kcp)**: Read Kindle books on your Mac. Available via brew as `kindle`.
- **[KnockKnock](https://objective-see.org/products/knockknock.html)**: See what's persistently installed on your Mac.
- **[Marked 2](https://marked2app.com)**: Markdown previewer. Available via brew as `marked`.
- **[MuffinTerm](https://apps.apple.com/us/app/muffinterm/id1583236494)**: A terminal emulator for macOS crafted for the classic BBS experience.
- **[Numbers](https://www.apple.com/numbers/)**: Create impressive spreadsheets. Available via Mac App Store.
- **[Onyx](https://www.titanium-software.fr/en/onyx.html)**: Verify system files structure, run miscellaneous maintenance and more. Available via brew as `onyx`.
- **[Pages](https://www.apple.com/pages/)**: Documents that stand apart. Available via Mac App Store.
- **[PhotoSweeper](https://overmacs.com)**: A fast & powerful duplicate photos cleaner for Mac. Available via brew as `photosweeper-x`.
- **[Pixelmator Classic](https://www.pixelmator.com/mac/)**: Powerful, full-featured image editor for Mac. Available via Mac App Store.
- **[Platypus](https://sveinbjorn.org/platypus)**: Create native Mac applications from command line scripts. Available via brew as `platypus`.
- **[Pocket Sync](https://github.com/neil-morrison44/pocket-sync)**: Manage your Analogue Pocket's games, saves, and more. Available via brew as `pocket-sync`.
- **[SiteSucker](https://ricks-apps.com/osx/sitesucker/)**: Download websites from the Internet. Available via Mac App Store.
- **[TaskExplorer](https://objective-see.org/products/taskexplorer.html)**: Explore all the tasks (processes) running on your Mac with TaskExplorer.
- **[TestFlight](https://developer.apple.com/testflight/)**: Test beta versions of apps. Available via Mac App Store.
- **[UTM](https://mac.getutm.app/)** ([Open-Source](https://github.com/utmapp/UTM)): Virtual machine manager for macOS. Available via brew as `utm` and Mac App Store.
- **[XLD](https://tmkk.undo.jp/xld/index_e.html)**: Lossless audio decoder.

### As Needed GUI Software for Windows

- **[Autoruns](https://learn.microsoft.com/en-us/sysinternals/downloads/autoruns)** (from [Sysinternals](https://learn.microsoft.com/en-us/sysinternals/)): See what programs are configured to startup automatically when your system boots and you login.
- **[BleachBit](https://www.bleachbit.org)**: Clean Your System and Free Disk Space. Available via winget as `BleachBit.BleachBit`.
- **[Exact Audio Copy](https://www.exactaudiocopy.de)**: Audio grabber for audio CDs using standard CD and DVD-ROM drives
- **[foobar2000](https://www.foobar2000.org)**: Advanced freeware audio player. Available via winget as `PeterPawlowski.foobar2000` and scoop as `foobar2000`.
- **[ImDisk](https://sourceforge.net/projects/imdisk-toolkit/)**: Mount image files of hard drive, cd-rom or floppy.
- **[ImgBurn](https://www.imgburn.com)**: A lightweight CD / DVD / HD DVD / Blu-ray burning application. Available via winget as `LIGHTNINGUK.ImgBurn`.
- **[OSFMount](https://www.osforensics.com/tools/mount-disk-images.html)**: Mount raw and other disk image files as virtual drives (forensic-style, typically read-only). Available via winget as `PassmarkSoftware.OSFMount`.
- **[Paint.NET](https://getpaint.net)**: Free image and photo editing software for Windows. Available via scoop as `paint.net` and winget as `dotPDNLLC.paintdotnet`.
- **[Process Explorer](https://learn.microsoft.com/en-us/sysinternals/downloads/process-explorer)** (from [Sysinternals](https://learn.microsoft.com/en-us/sysinternals/)): Find out what files, registry keys and other objects processes have open, which DLLs they have loaded, and more.
- **[WinCDEmu](https://wincdemu.sysprogs.org/)**: Open-source CD/DVD/BD emulator for mounting optical disc images (ISO, CUE/BIN, MDF/MDS, NRG, CCD/IMG). Available via scoop as `extras/wincdemu`.
- **[WinImage](https://www.winimage.com/winimage.htm)**: A fully-fledged disk-imaging suite for easy creation, reading and editing of many image formats and fileystems.
- **[WinSCP](https://winscp.net/)**: A popular SFTP client and FTP client for Microsoft Windows. Available via scoop, and winget as `WinSCP.WinSCP`.

### As Needed GUI Software for Windows and Linux

- **[HexChat](https://hexchat.github.io)**: An IRC client based on XChat. Available via brew, nix, scoop, and winget as `HexChat.HexChat`.
