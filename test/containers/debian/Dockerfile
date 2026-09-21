FROM debian:latest@sha256:9cc080028c43b27d2074d63a5f9caf7166d731494965616c1a6d2827a004585c

# setup-root installs ca-certificates, curl, git, sudo; the Dockerfile
# is only responsible for locale setup (which setup-root does not handle).
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        dbus \
        locales \
    && sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
