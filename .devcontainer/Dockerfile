FROM mcr.microsoft.com/devcontainers/base:jammy

USER root

ARG USERNAME="vscode"

# Used to persist bash history as per https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory \
    && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc"

RUN apt-get update && apt-get install --no-install-recommends -y \
    curl \
    git-lfs \
    sudo \
    vim \
    zsh \
    && rm -rf /var/lib/apt/lists/* \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER vscode

# Create the vscode server directory to allow for devcontainer persistence via a profile volume
RUN mkdir -p ~/.vscode-server

ENV SHELL /bin/bash

# Make sure we’re root for UID/GID adjusting
USER root

# Install gosu for privilege dropping
RUN apt-get update && \
    apt-get install -y gosu && \
    rm -rf /var/lib/apt/lists/*

# Copy the PUID/PGID entrypoint script from the repo
COPY entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD ["bash"]
