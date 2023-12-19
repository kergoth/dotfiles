#!/usr/bin/env bash

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
        CPPFLAGS="$CPPFLAGS -Wno-unused-value -Wno-empty-body -Qunused-arguments \
                         -Wno-parentheses-equality -Wno-nullability-completeness"
        if command -v brew >/dev/null 2>&1; then
            CPPFLAGS="-I$(xcrun --show-sdk-path)/usr/include"
        fi

        # The python 3 build chokes due to a lack of llvm-ar at the moment
        PYTHON_NO_LTO=1
        ;;
esac

if command -v brew >/dev/null 2>&1; then
    eval "$(brew environment --shell=auto | grep -vw PATH)"
    for brew in openssl readline sqlite xz zlib expat bzip2 libffi; do
        if brew_prefix="$(brew --prefix "$brew")" && [ -n "$brew_prefix" ]; then
            CPPFLAGS="$CPPFLAGS -I$brew_prefix/include"
            LDFLAGS="$LDFLAGS -L$brew_prefix/lib"
        fi
    done
fi

echo $CPPFLAGS $LDFLAGS

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
