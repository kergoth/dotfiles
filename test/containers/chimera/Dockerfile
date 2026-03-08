FROM chimeralinux/chimera:latest

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
