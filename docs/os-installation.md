# Operating System Installation

Some platforms have lower-level scripts for fresh OS installation or live environments:

- **`os-install`** (`script/{distro}/os-install`): Installs the OS from a live environment. Available for Arch and Chimera Linux.
- **`setup-root`** (`script/{distro}/setup-root`): Runs as root to create users, install base packages, and prepare for `setup-full`. Available for Arch, Chimera Linux, and FreeBSD.

## WSL2 Arch Linux Installation (ArchWSL)

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

## WSL2 Chimera Linux Installation

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

## Chimera Linux Installation

- Attach the Chimera Linux Live CD ISO to a VM or USB drive and boot from it.
- If not using a `base` ISO, wait for the graphical environment to load. It will take a few seconds.
- If using a `base` ISO, log in as `anon`.
- Run the `Konsole` app.
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
doas dinitctl enable networkmanager
# Wait a second for the DHCP client to get an IP address
~/.dotfiles/script/setup-full
```
