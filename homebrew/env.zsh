export HOMEBREW_AUTO_UPDATE=1
export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-~/.brew}

# Optional structure for a dual-homebrew setup for admin vs non-admin
case "$OSTYPE" in
    darwin*)
        export ADMIN_HOMEBREW_PREFIX="${ADMIN_HOMEBREW_PREFIX:-/opt/homebrew}"
        case "$LOGNAME" in
            "$OSX_ADMIN_LOGNAME")
                export HOMEBREW_PREFIX="$ADMIN_HOMEBREW_PREFIX"
                ;;
        esac
        ;;
esac
