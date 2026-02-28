FROM archlinux:latest

RUN pacman-key --init \
    && pacman-key --populate \
    && pacman --noconfirm -Syu \
    && pacman --noconfirm --needed -S \
        curl \
        git \
        sudo
