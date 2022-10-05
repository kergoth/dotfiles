if [ -d ~/.nix ] && ! [ -d /nix ]; then
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

path=(~/.nix/shims $path)
