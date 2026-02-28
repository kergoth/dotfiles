ARG BASE_IMAGE=archlinux/archlinux:latest
FROM ${BASE_IMAGE}

RUN locale-gen
RUN pacman-key --init \
    && pacman-key --populate \
    && pacman --noconfirm -Syu \
    && pacman --noconfirm --needed -S \
        curl \
        git \
        sudo
