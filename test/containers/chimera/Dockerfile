FROM chimeralinux/chimera:latest@sha256:b58ec2b8c80561ba8f41d8852463585d22299b38737ce36d7d926cabf9c94174

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
