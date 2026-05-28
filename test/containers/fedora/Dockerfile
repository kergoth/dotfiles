FROM fedora:latest@sha256:6c75d5bf57cb0fa5aa4b92c6a83c86c791644496d9ac230de7711f5b8ec3b898

RUN dnf -y upgrade \
    && dnf -y install \
        ca-certificates \
        curl \
        dbus \
        git \
        sudo \
    && dnf -y clean all \
    && rm -rf /var/cache/dnf

RUN if [ -f /etc/crypto-policies/back-ends/openssh.config ] \
    && grep -q '^GSSAPIKexAlgorithms[[:space:]]' /etc/crypto-policies/back-ends/openssh.config; then \
        for cfg in /etc/ssh/ssh_config /etc/ssh/ssh_config.d/*.conf; do \
            [ -f "$cfg" ] || continue; \
            sed -i \
                -e 's|^[[:space:]]*Include[[:space:]]\+/etc/crypto-policies/back-ends/openssh\.config|# Disabled: crypto-policies client include (GSSAPIKexAlgorithms unsupported in container ssh)|' \
                "$cfg"; \
        done; \
    fi

ENV LANG=C.UTF-8
