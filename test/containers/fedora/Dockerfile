FROM fedora:latest

RUN dnf -y upgrade \
    && dnf -y install \
        ca-certificates \
        curl \
        git \
        sudo \
    && dnf -y clean all \
    && rm -rf /var/cache/dnf

ENV LANG=C.UTF-8
