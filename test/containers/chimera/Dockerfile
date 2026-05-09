FROM chimeralinux/chimera:latest@sha256:29102d7e12a1f464707d7aba19ce53e652d277861838ed4129178d0655444b1a

RUN apk add --no-cache --no-interactive \
        ca-certificates \
        curl \
        dbus \
        git \
        opendoas \
        shadow

# musl treats all locale names as valid C.UTF-8 aliases; no langpack needed.
# Set LANG so dotfiles don't run locale detection on every shell start.
ENV LANG=C.UTF-8
