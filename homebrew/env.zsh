export HOMEBREW_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-~/.brew}
export HOMEBREW_CASK_OPTS="--appdir=~/Applications"
HOMEBREWS_HOME="${HOMEBREWS_HOME:-$XDG_DATA_HOME/homebrews}"

# Optional structure for a dual-homebrew setup for admin vs non-admin
case "$OSTYPE" in
    darwin*)
        export ADMIN_HOMEBREW_PREFIX="${ADMIN_HOMEBREW_PREFIX:-/Users/Shared/homebrew}"
        case "$LOGNAME" in
            "$OSX_ADMIN_LOGNAME")
                export HOMEBREW_PREFIX="$ADMIN_HOMEBREW_PREFIX"
                ;;
        esac
        ;;
esac
