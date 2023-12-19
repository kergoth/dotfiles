if [ -d ~/.nix ]; then
    home_nix=1
else
    home_nix=
fi

for f in etc/profile.d/nix-daemon.sh etc/profile.d/nix.sh etc/profile.d/hm-session-vars.sh; do
    for profile_dir in ~/.nix-profile ~/.nix/var/nix/profiles/per-user/$USER/profile \
                       /nix/var/nix/profiles/per-user/$USER/profile \
                       /nix/var/nix/profiles/default; do
        if [ -e "$profile_dir/$f" ]; then
            . "$profile_dir/$f"
            break
        fi
    done
done

path=(~/.local/bin ~/.nix/shims $path)

if [[ -e ~/.nix-profile ]]; then
    manpath=(~/.nix-profile/share/man $manpath)
    fpath=(~/.nix-profile/share/zsh/site-functions $fpath)
    path=(~/.nix-profile/bin $path)
    xdg_data_dirs=(~/.nix-profile/share $xdg_data_dirs)
fi

if [[ -n $buildInputs ]]; then
    for p in $=buildInputs; do
        manpath=($p/share/man $manpath)
        fpath=($p/share/zsh/site-functions $fpath)
        path=($p/bin $path)
        xdg_data_dirs=($p/share $xdg_data_dirs)
    done
fi
