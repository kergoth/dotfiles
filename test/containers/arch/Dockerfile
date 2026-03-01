# check=skip=InvalidBaseImagePlatform
ARG BASE_IMAGE=archlinux/archlinux:latest
FROM ${BASE_IMAGE}

RUN locale-gen

ENV LANG=en_US.UTF-8

RUN pacman-key --init \
    && pacman-key --populate \
    && pacman --noconfirm -Syu \
    && pacman --noconfirm --needed -S sudo \
    && rm -rf /var/cache/pacman/pkg/*
