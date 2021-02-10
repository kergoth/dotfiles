# Ensure we can run llvm-profdata on FreeBSD
for llvmdir in /usr/local/llvm*/bin; do
    if [ -d "$llvmdir" ]; then
        PATH="$PATH:$llvmdir"
    fi
done

export PYTHONNOUSERSITE=1
export CFLAGS="${CFLAGS--O2}"
export CPPFLAGS="${CPPFLAGS-}"
export LDFLAGS="${LDFLAGS:-}"

case "${OSTYPE:-}" in
    darwin*)
        # Silence spammy warnings on clang builds, as mentioned in the python
        # developer documentation.
        export CPPFLAGS="-Wno-unused-value -Wno-empty-body -Qunused-arguments \
                         -Wno-parentheses-equality -Wno-nullability-completeness"
        if command -v brew >/dev/null 2>&1; then
            eval "$(brew environment --shell=auto | grep -vw PATH)"
            export CPPFLAGS="$CPPFLAGS -I$(brew --prefix sqlite)/include -I$(brew --prefix openssl@1.1)/include -I$(xcrun --show-sdk-path)/usr/include"
            export LDFLAGS="$LDFLAGS -L$(brew --prefix sqlite)/lib -L$(brew --prefix openssl@1.1)/lib"
            # The python 3 build chokes due to a lack of llvm-ar at the moment
            PYTHON_NO_LTO=1
        fi
        ;;
    *)
        if [ -e /etc/arch-release ]; then
            CPPFLAGS="$CPPFLAGS -I/usr/include/openssl-1.0"
            LDFLAGS="$LDFLAGS -L/usr/lib/openssl-1.0"
        fi
        ;;
esac

if [ -z "${CONFIGURE_OPTS:-}" ] && [ -z "${PYTHON_CONFIGURE_OPTS:-}" ]; then
    export PYTHON_CONFIGURE_OPTS="\
        --enable-shared \
        --with-system-expat \
        --with-system-zlib \
        --enable-loadable-sqlite-extensions \
    "
    if [ "$(uname -s)" = FreeBSD ]; then
        PYTHON_NO_PGO=1
        PYTHON_NO_LTO=1
    fi
    if [ -z "${PYTHON_NO_PGO:-}" ]; then
        PYTHON_CONFIGURE_OPTS="$PYTHON_CONFIGURE_OPTS --enable-optimizations"
    fi
    if [ -z "${PYTHON_NO_LTO:-}" ]; then
        PYTHON_CONFIGURE_OPTS="$PYTHON_CONFIGURE_OPTS --with-lto"
    fi
fi
