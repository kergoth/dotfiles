FROM mcr.microsoft.com/devcontainers/base:jammy

USER root

ENV USERNAME vscode

# Used to persist bash history as per https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory \
    && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc"

RUN apt-get update && apt-get install --no-install-recommends -y \
    curl \
    git-lfs \
    repo \
    sudo \
    zsh \
    \
    python3-pip python3-setuptools python3-wheel python3-yaml python3-distro python3-jsonschema \
    python3-newt python3-colorlog python3-kconfiglib \
    \
    && rm -rf /var/lib/apt/lists/* \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && ln -s /usr/bin/python3 /usr/local/bin/python

RUN pip install kas

RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list \
    && apt-get update && apt-get install -y gum \
    && rm -rf /var/lib/apt/lists/*

USER vscode

# Install pkgx
RUN eval "$(curl -Ssf --proto '=https' https://pkgx.sh)"

# Install repo, devbox
RUN mkdir -p ~/.local/bin \
    && PATH="${HOME}/.local/bin:${PATH}" \
    && curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.local/bin/repo \
    && chmod a+rx ~/.local/bin/repo \
    && curl -fsSL https://releases.jetpack.io/devbox >~/.local/bin/devbox \
    && chmod a+rx ~/.local/bin/devbox

# Install zoxide
RUN eval "$(curl -Ssf --proto '=https' https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh)"

RUN echo 'PATH="${HOME}/bin:${HOME}/.local/bin:${PATH}"' >>~/.bashrc

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
