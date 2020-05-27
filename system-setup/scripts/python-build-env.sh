# Ensure we can run llvm-profdata on FreeBSD
for llvmdir in /usr/local/llvm*/bin; do
    if [ -d "$llvmdir" ]; then
        PATH="$PATH:$llvmdir"
    fi
done

export PYTHONNOUSERSITE=1
export CFLAGS="${CFLAGS--O2}"
export LDFLAGS="${LDFLAGS:-}"

no_lto=0
no_pgo=0

case "$OSTYPE" in
    darwin*)
        if command -v brew >/dev/null 2>&1; then
            eval "$(brew environment --shell=auto | grep -vw PATH)"
            CFLAGS="$CFLAGS -I$(brew --prefix sqlite)/include -I$(brew --prefix openssl@1.1)/include -I$(xcrun --show-sdk-path)/usr/include"
            LDFLAGS="$LDFLAGS -L$(brew --prefix sqlite)/lib -L$(brew --prefix openssl@1.1)/lib"
            # The python 3 build chokes due to a lack of llvm-ar at the moment
            no_lto=1
        fi
        # Silence spammy warnings on clang builds, as mentioned in the python
        # developer documentation.
        export CPPFLAGS="-Wno-unused-value -Wno-empty-body -Qunused-arguments \
                         -Wno-parentheses-equality -Wno-nullability-completeness"
        ;;
    *)
        if [ -e /etc/arch-release ]; then
            CFLAGS="$CFLAGS -I/usr/include/openssl-1.0"
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
    if [ "$OSTYPE" = linux-gnu ]; then
        case "$(uname -r)" in
            *-Microsoft)
                # WSL. test_ssl keeps hanging indefinitely
                no_pgo=1
                ;;
        esac
    elif [ "$(uname -s)" = FreeBSD ]; then
        no_pgo=1
        no_lto=1
    fi
    if [ $no_pgo -eq 0 ]; then
        PYTHON_CONFIGURE_OPTS="$PYTHON_CONFIGURE_OPTS --enable-optimizations"
    fi
    if [ $no_lto -eq 0 ]; then
        PYTHON_CONFIGURE_OPTS="$PYTHON_CONFIGURE_OPTS --with-lto"
    fi
fi
unset no_pgo no_lto
