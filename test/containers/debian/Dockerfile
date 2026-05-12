FROM debian:latest@sha256:e2d08da6f42ef4b09b165d55528a12727aeed8240dc9edf888e3ec07e10ef9da

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
