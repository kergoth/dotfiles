export KERL_CONFIGURE_OPTIONS="--without-javac"

case "${OSTYPE:-}" in
    darwin*)
        if command -v brew >/dev/null 2>&1; then
            KERL_CONFIGURE_OPTIONS="$KERL_CONFIGURE_OPTIONS --with-ssl=$(brew --prefix openssl)"
        fi
        ;;
esac
