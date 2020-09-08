INSTALL_DEST="${INSTALL_DEST:-$HOME}"

: "${XDG_CONFIG_HOME:=$INSTALL_DEST/.config}"
: "${XDG_DATA_HOME:=$INSTALL_DEST/.local/share}"
: "${XDG_CACHE_HOME:=$INSTALL_DEST/.cache}"

export ASDF_DATA_DIR="${ASDF_DATA_DIR:-${XDG_DATA_HOME:-$INSTALL_DEST/.local/share}/asdf}"
export ASDF_CONFIG_FILE="${ASDF_CONFIG_FILE:-${XDG_CONFIG_HOME:-$INSTALL_DEST/.config}/asdfrc}"
export PYENV_ROOT="${PYENV_ROOT:-${XDG_DATA_HOME:-$INSTALL_DEST/.local/share}/pyenv}"

DOTFILESDIR="${DOTFILESDIR:-$(cd "$(dirname "$(dirname "$0")")" && pwd -P)}"

PATH="$ASDF_DATA_DIR/shims:$PYENV_ROOT/bin:$PYENV_ROOT/shims:$INSTALL_DEST/.local/bin:$DOTFILESDIR/external/scripts:$PATH"

HOSTNAME=${HOSTNAME:-${HOST:-$(hostname -s)}}
osname="$(uname -s)"
prefixes="%include %include%${osname} %include%${HOSTNAME}"
install_force="${install_force:-0}"

case "$OSTYPE" in
    darwin*)
        : "${XDG_CACHE_HOME:=$INSTALL_DEST/Library/Caches}"
        ;;
    linux-gnu)
        case "$(uname -r)" in
            *-Microsoft)
                OSTYPE=WSL
                USERPROFILE="${USERPROFILE:-$(wslpath "$(cmd.exe /D /C 'SET /P <NUL=%USERPROFILE%' 2>/dev/null)")}"
                prefixes="%include%Wsl $prefixes"

                if [ -z "${WslDisks:-}" ]; then
                    export WslDisks=/mnt
                    if [ -e /etc/wsl.conf ]; then
                        WslDisks="$(sed -n -e 's/^root = //p' /etc/wsl.conf)"
                        if [ -n $WslDisks ]; then
                            export WslDisks="${WslDisks%/}"
                        else
                            WslDisks=/mnt
                        fi
                    fi
                fi
                ;;
        esac
        ;;
esac

set_launchd () {
    var="$1"
    value="$2"

    case "$OSTYPE" in
        darwin*)
            ;;
        *)
            return
            ;;
    esac

    plist_set () {
        plist_key="$(printf "%s" "$1" | sed "s/'/\\\\'/g")"
        plist_val="$(printf "%s" "$2" | sed "s/'/\\\\'/g")"
        if /usr/libexec/PlistBuddy -c "Print '$plist_key'" "$3" >/dev/null 2>&1; then
            /usr/libexec/PlistBuddy -c "Set '$plist_key' '$plist_val'" "$3"
        else
            /usr/libexec/PlistBuddy -c "Add '$plist_key' "${4:-string}" '$plist_val'" "$3"
        fi
    }

    mkdir -p $INSTALL_DEST/.MacOSX
    plist_set "$var" "$value" $INSTALL_DEST/.MacOSX/environment.plist

    if which launchctl &>/dev/null; then
        launchctl setenv "$var" "$value"
    fi

    if [ ! -e $INSTALL_DEST/Library/PreferencePanes/EnvPane.prefPane ]; then
        printf >&2 "Warning: EnvPane is not installed, set of env var %s to %s will not persist\n" "$var" "$value"
    fi
}

link () {
    # Link a file to a destination using a relative path, with particular
    # convenience handling for dotfiles. ex.:
    #
    # link zsh/.zshenv.redir $INSTALL_DEST/.zshenv.redir
    # link zshrc       # links to $INSTALL_DEST/.zshrc (relatively)
    # link config/curl # links to $INSTALL_DEST/.config/curl (relatively)
    dotfile="$(abspath "$1")"
    if [ $# -gt 1 ]; then
        dotfile_dest="$(abspath "$2")"
    else
        dotfile_base="${dotfile##*/}"
        case "$dotfile_base" in
            .*)
                dotfile_dest="$INSTALL_DEST/$dotfile_base"
                ;;
            *)
                dotfile_dest="$INSTALL_DEST/.$dotfile_base"
                ;;
        esac
    fi
    destdir="${dotfile_dest%/*}"

    wsl_winpath=0
    if [ $OSTYPE = WSL ]; then
        case "$(pwd -P)" in
            "$WslDisks"/*)
                ;;
            *)
                case "$dotfile_dest" in
                    "$WslDisks"/*)
                        wsl_winpath=1
                        ;;
                esac
                ;;
        esac
    fi

    if [ "$install_force" -eq 1 ]; then
        rm -rf "$dotfile_dest"
    elif [ -h "$dotfile_dest" ]; then
        existing_target="$(readlink "$dotfile_dest")"
        if [ -z "$existing_target" ] && [ $wsl_winpath -eq 1 ]; then
            existing_target="$(powershell.exe -c "(Get-Item '$(_winpath "$dotfile_dest")').Target" 2>/dev/null | tr -d '\r')" || :
            if [ -n "$existing_target" ]; then
                existing_target="$(wslpath -u "$existing_target")"
                case "$existing_target" in
                    UNC/wsl\$/*)
                        existing_target="/$(echo "$existing_target" | cut -d/ -f4-)"
                        ;;
                esac
            fi
        fi

        case "$existing_target" in
            /*)
                ;;
            *)
                existing_target="$(normalize_path "$destdir/$existing_target")"
                ;;
        esac

        if [ "$existing_target" != "$dotfile" ]; then
            rm -f "$dotfile_dest"
        else
            return
        fi
    fi

    mkdir -p "$destdir"
    if false && [ $wsl_winpath -eq 1 ]; then
        if [ -e "$dotfile_dest" ]; then
            # Not using iln, so prompt to handle existing
            if prompt_bool "Replace $dotfile_dest?"; then
                mv "$dotfile_dest" "$dotfile_dest.old"
            else
                dotfile_dest="$dotfile_dest.new"
            fi
        fi
        mklink "$dotfile_dest" "$dotfile" >/dev/null
    else
        iln -srib "$dotfile" "$dotfile_dest"
    fi
    echo >&2 "Linked $(homepath "$dotfile_dest")"
}

_winpath () {
    case "$1" in
        "$WslDisks"/*)
            echo "$1" | sed -e "s#^$WslDisks/\([^/]*\)/#\1:/#; s#/#\\\\#g"
            ;;
        *)
            wslpath -wa "$1"
            ;;
    esac
}

mklink () {
    (
        cd "$WslDisks/c" || exit 1
        link="$1"
        case "$link" in
            "$WslDisks"/*)
                link="$(echo "$link" | sed -e "s#^$WslDisks/\([^/]*\)/#\1:/#; s#/#\\\\#g")"
                ;;
        esac
        if [ -d "$2" ]; then
            cmd.exe /c mklink /j "$link" "$(_winpath "$2")"
        else
            cmd.exe /c mklink "$link" "$(_winpath "$2")"
        fi
    )
}

prompt_bool () {
    if [[ $# -gt 1 ]]; then
        default="$2"
    else
        default="y"
    fi
    case $default in
        [yY])
            y_side="Y"
            n_side="n"
            default_code=0
            ;;
        [nN])
            n_side="N"
            y_side="y"
            default_code=1
            ;;
    esac

    while true; do
        read -r -n 1 -p "$1 [$y_side|$n_side] " result </dev/tty
        printf "\n"
        case "$result" in
            [yY])
                return 0
                ;;
            [nN])
                return 1
                ;;
            "")
                return $default_code
                ;;
            *)
                echo >&2 "Invalid input '$result'"
                ;;
        esac
    done
}

homepath () {
    echo "$@" | sed -e "s#^~/#$INSTALL_DEST/#" | if [ -n "${USERPROFILE:-}" ]; then sed -e "s#^$USERPROFILE/#\$USERPROFILE/#"; else cat; fi
}

abspath () {
    # Return an absolute path for the specified argument
    _path="$1"
    if [ -n "${_path##/*}" ]; then
        _path="$(pwd -P)/$1"
    fi
    echo "$_path"
}

normalize_path()
{
    # Attempt to normalize the specified path, removing . and ..

    # Remove all /./ sequences.
    local path="${1//\/.\//\/}"

    # Remove dir/.. sequences.
    while [[ $path =~ ([^/][^/]*/\.\./) ]]
    do
        path="${path/${BASH_REMATCH[0]}/}"
    done
    echo "$path"
}

install_templated () {
    # Extremely basic template file generation, currently only implements
    # %include, which does what you would expect
    dotfile_dest="$2"
    destdir="${dotfile_dest%/*}"
    if [ "$destdir" != "$dotfile_dest" ]; then
        mkdir -p "$destdir"
    fi

    cat "$1" | while IFS='|' read -r line; do
        files=
        for prefix in $prefixes; do
            case "$line" in
                $prefix\ *)
                    files="${line#$prefix }"
                    ;;
            esac
        done

        if [ -z "$files" ]; then
            case "$line" in
                %include%*)
                    ;;
                *)
                    printf "%s\n" "$line"
                    ;;
            esac
            continue
        fi

        for file in $(echo $files); do
            if [ -f "$file" ]; then
                cat "$file"
            fi
        done
    done >"$dotfile_dest"
    echo >&2 "Wrote $(abspath "$dotfile_dest")"
}

merge_to () {
    # Convenience wrapper for merging multiple files into one dotfile
    dotfile_dest="$1"
    destdir="${dotfile_dest%/*}"
    if [ "$destdir" != "$dotfile_dest" ]; then
        mkdir -p "$destdir"
    fi
    shift
    cat "$@" >$dotfile_dest
    echo >&2 "Wrote $(abspath "$dotfile_dest")"
}
