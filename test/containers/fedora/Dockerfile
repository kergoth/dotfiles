FROM fedora:latest

RUN dnf -y upgrade \
    && dnf -y install \
        ca-certificates \
        curl \
        git \
        glibc-langpack-en \
        sudo \
    && dnf -y clean all \
    && rm -rf /var/cache/dnf

ENV LANG=en_US.UTF-8
