FROM node:22-bookworm-slim

# Install system dependencies & build tools (for native npm modules)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    jq \
    gnupg \
    apt-transport-https \
    make \
    g++ \
    build-essential \
    python3 \
    python-is-python3 \
    tini \
    gosu \
    procps \
    net-tools \
    iproute2 \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

# Create 'opencode' user and group with UID 1000, and delete the existing 'node' user first to reclaim the UID
RUN userdel -r node && \
    groupadd -g 1000 opencode && \
    useradd -u 1000 -g opencode -m -s /bin/bash opencode

# Install gh-cli
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && apt-get install -y kubectl && \
    rm -rf /var/lib/apt/lists/*

# Install yq
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

# Install dyff
RUN curl -sL https://github.com/homeport/dyff/releases/download/v1.9.1/dyff_1.9.1_linux_amd64.tar.gz | tar -xz -C /usr/local/bin dyff

# Install opencode
RUN npm install -g pm2 && \
    curl -fsSL https://opencode.ai/install | bash && \
    mv /root/.opencode/bin/opencode /usr/local/bin/opencode && \
    chmod +x /usr/local/bin/opencode

# Install openchamber
RUN curl -fsSL https://raw.githubusercontent.com/openchamber/openchamber/main/scripts/install.sh | bash

# Configure home directory
RUN chown -R opencode:opencode /home/opencode

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER root
WORKDIR /home/opencode
EXPOSE 3000

STOPSIGNAL SIGINT

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/entrypoint.sh"]
