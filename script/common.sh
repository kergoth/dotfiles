: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"

export ASDF_DATA_DIR="${ASDF_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/asdf}"
export ASDF_CONFIG_FILE="${ASDF_CONFIG_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/asdfrc}"
export PYENV_ROOT="${PYENV_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/pyenv}"

DOTFILESDIR="${DOTFILESDIR:-$(cd "$(dirname "$(dirname "$0")")" && pwd -P)}"

PATH="$ASDF_DATA_DIR/shims:$PYENV_ROOT/bin:$PYENV_ROOT/shims:$HOME/.local/bin:$DOTFILESDIR/external/scripts:$PATH"

HOSTNAME=$(hostname -s)
osname="$(uname -s)"
prefixes="%include %include%${osname} %include%${HOSTNAME}"
install_force="${install_force:-0}"

case "$OSTYPE" in
    darwin*)
        : "${XDG_CACHE_HOME:=~/Library/Caches}"
        ;;
    linux-gnu)
        case "$(uname -r)" in
            *-Microsoft)
                OSTYPE=WSL
                USERPROFILE="${USERPROFILE:-$(wslpath "$(cmd.exe /D /C 'SET /P <NUL=%USERPROFILE%' 2>/dev/null)")}"
                prefixes="%include%Wsl $prefixes"
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

    mkdir -p ~/.MacOSX
    plist_set "$var" "$value" ~/.MacOSX/environment.plist

    if which launchctl &>/dev/null; then
        launchctl setenv "$var" "$value"
    fi

    if [ ! -e ~/Library/PreferencePanes/EnvPane.prefPane ]; then
        printf >&2 "Warning: EnvPane is not installed, set of env var %s to %s will not persist\n" "$var" "$value"
    fi
}

link () {
    # Link a file to a destination using a relative path, with particular
    # convenience handling for dotfiles. ex.:
    #
    # link zsh/.zshenv.redir ~/.zshenv.redir
    # link zshrc       # links to ~/.zshrc (relatively)
    # link config/curl # links to ~/.config/curl (relatively)
    dotfile="$(abspath "$1")"
    if [ $# -gt 1 ]; then
        dotfile_dest="$(abspath "$2")"
    else
        dotfile_base="${dotfile##*/}"
        case "$dotfile_base" in
            .*)
                dotfile_dest="$HOME/$dotfile_base"
                ;;
            *)
                dotfile_dest="$HOME/.$dotfile_base"
                ;;
        esac
    fi
    destdir="${dotfile_dest%/*}"
    if [ $install_force -eq 1 ]; then
        rm -f "$dotfile_dest"
    elif [ -h "$dotfile_dest" ]; then
        existing_dest="$(readlink "$dotfile_dest")"
        case "$existing_dest" in
            /*)
                ;;
            *)
                existing_dest="$(normalize_path "$destdir/$existing_dest")"
                ;;
        esac
        if [ "$existing_dest" != "$dotfile" ]; then
            rm -f "$dotfile_dest"
        else
            return
        fi
    fi
    mkdir -p "$destdir"
    iln -srib "$dotfile" "$dotfile_dest"
    echo >&2 "Linked $(homepath "$dotfile_dest")"
}

homepath () {
    echo "$@" | sed -e "s#^$HOME/#~/#" | if [ -n "${USERPROFILE:-}" ]; then sed -e "s#^$USERPROFILE/#\$USERPROFILE/#"; else cat; fi
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

    cat "$1" | while IFS='|' read line; do
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
            cat "$file"
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
