FROM ubuntu:24.04
SHELL ["/bin/bash","-eux","-o","pipefail","-c"]

ARG NODE_VERSION=24.x
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Europe/Brussels
ENV TZ=$TZ

# Tool versions - automatically updated by Renovate
# renovate: datasource=github-releases depName=argoproj/argo-cd
ARG ARGOCD_VERSION=v2.14.21
# renovate: datasource=github-releases depName=eza-community/eza
ARG EZA_VERSION=v0.23.4
# renovate: datasource=github-releases depName=hadolint/hadolint
ARG HADOLINT_VERSION=v2.14.0
# renovate: datasource=github-releases depName=derailed/k9s
ARG K9S_VERSION=v0.50.18
# renovate: datasource=github-releases depName=kubecolor/kubecolor
ARG KUBECOLOR_VERSION=v0.5.3
# renovate: datasource=github-releases depName=yannh/kubeconform
ARG KUBECONFORM_VERSION=v0.7.0
# renovate: datasource=github-releases depName=ahmetb/kubectx
ARG KUBECTX_VERSION=v0.9.5
# renovate: datasource=github-releases depName=bitnami-labs/sealed-secrets
ARG KUBESEAL_VERSION=v0.34.0
# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize
ARG KUSTOMIZE_VERSION=v5.8.0
# renovate: datasource=github-releases depName=jesseduffield/lazygit
ARG LAZYGIT_VERSION=v0.58.1
# renovate: datasource=github-releases depName=gitleaks/gitleaks
ARG GITLEAKS_VERSION=v8.30.0
# renovate: datasource=github-releases depName=starship/starship
ARG STARSHIP_VERSION=v1.24.2
# renovate: datasource=github-releases depName=stern/stern
ARG STERN_VERSION=v1.31.0
# renovate: datasource=github-releases depName=siderolabs/talos
ARG TALOS_VERSION=v1.12.1
# renovate: datasource=github-releases depName=go-task/task
ARG TASK_VERSION=v3.46.4
# renovate: datasource=github-releases depName=terraform-linters/tflint
ARG TFLINT_VERSION=v0.60.0
# renovate: datasource=github-releases depName=aquasecurity/trivy
ARG TRIVY_VERSION=v0.68.2
# renovate: datasource=github-releases depName=mikefarah/yq
ARG YQ_VERSION=v4.50.1
# renovate: datasource=npm depName=cspell
ARG CSPELL_VERSION=9.6.0

# Install system dependencies grouped by purpose
RUN <<EOF
  apt-get update && apt-get -y upgrade && \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
  apt-get install -y --no-install-recommends \
    apt-utils \
    ca-certificates \
    curl \
    dialog \
    gnupg \
    gnupg2 \
    lsb-release \
    software-properties-common \
    sudo \
    tzdata \
    wget \
    which \
    build-essential \
    cmake \
    gcc \
    pkg-config \
    bash-completion \
    dumb-init \
    init-system-helpers \
    less \
    locales \
    man-db \
    manpages \
    nano \
    tmux \
    vim \
    bat \
    direnv \
    fd-find \
    fzf \
    git-delta \
    ripgrep \
    git \
    git-crypt \
    iproute2 \
    net-tools \
    netbase \
    openssh-client \
    htop \
    lsof \
    ncdu \
    procps \
    psmisc \
    strace \
    tree \
    bzip2 \
    tar \
    unzip \
    xz-utils \
    zip \
    fuse-overlayfs \
    podman \
    pipx \
    python3 python3-cffi python3-pip python3-venv python3-yaml python3-wheel \
    ansible \
    ansible-lint \
    yamllint \
    libc6 \
    libgcc1 \
    libgssapi-krb5-2 \
    libicu-dev \
    libkrb5-3 \
    liblttng-ust1t64 \
    libncurses-dev \
    libssh-dev \
    libssl-dev \
    libssl3 \
    libstdc++6 \
    zlib1g \
    dirmngr \
    jq \
    pinentry-curses \
    rsync \
    tldr \
    util-linux \
  && apt-get -y autoremove && apt-get -y autoclean && apt-get -y clean && rm -rf /var/lib/apt/lists/*
EOF

# Install GitHub CLI
# Note: GPG keys are obtained from official sources over HTTPS.
# For production environments, consider verifying key fingerprints before import.
RUN <<EOF
  mkdir -p -m 755 /etc/apt/keyrings
  out=$(mktemp) && curl -fsSL -o "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg
  cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  rm -f "$out"
  mkdir -p -m 755 /etc/apt/sources.list.d
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
EOF

# Configure nodesource - The installation will be done in later step
RUN <<EOF
  mkdir -p /usr/share/keyrings

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION nodistro main" | tee /etc/apt/sources.list.d/nodesource.list > /dev/null
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg
  chmod 644 /usr/share/keyrings/nodesource.gpg
  # Nodejs Config
  echo "Package: nodejs" | tee /etc/apt/preferences.d/nodejs > /dev/null
  echo "Pin: origin deb.nodesource.com" | tee -a /etc/apt/preferences.d/nodejs > /dev/null
  echo "Pin-Priority: 600" | tee -a /etc/apt/preferences.d/nodejs > /dev/null
EOF

# Add Postgresql repo
RUN <<EOF
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
      | gpg --dearmor \
      | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/apt.postgresql.org.gpg] https://apt.postgresql.org/pub/repos/apt $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release)-pgdg main" \
      | tee /etc/apt/sources.list.d/pgdg.list > /dev/null
EOF

# Add Helm repo
RUN <<EOF
    curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey \
      | gpg --dearmor \
      | tee /etc/apt/trusted.gpg.d/helm.gpg > /dev/null
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" \
      | tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null
EOF

# Add terraform repo
RUN <<EOF
    curl -fsSL https://apt.releases.hashicorp.com/gpg \
      | gpg --dearmor \
      | tee /etc/apt/trusted.gpg.d/hashicorp.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/hashicorp.gpg] https://apt.releases.hashicorp.com $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" \
      | tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
EOF

# Add Kubernetes repo
RUN <<EOF
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key \
      | gpg --dearmor \
      | tee /etc/apt/trusted.gpg.d/kubernetes-apt-keyring.gpg > /dev/null
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" \
      | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
EOF

# Add Azure CLI repo
RUN <<EOF
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor \
      | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" \
      | tee /etc/apt/sources.list.d/azure-cli.list > /dev/null
EOF

# Add Fish shell PPA
RUN <<EOF
    add-apt-repository -y ppa:fish-shell/release-4
EOF

# Install additional packages from additional repositories
RUN <<EOF
  apt-get update && apt-get install -y --no-install-recommends \
    azure-cli \
    fish \
    gh \
    helm \
    kubectl \
    nodejs \
    packer \
    postgresql-client \
    terraform \
  && apt-get -y autoremove && apt-get -y autoclean && apt-get -y clean && rm -rf /var/lib/apt/lists/*
EOF

# Install cspell globally via npm with pinned version
RUN <<EOF
  npm install -g cspell@${CSPELL_VERSION}
EOF

# Install Kubernetes ecosystem tools with pinned versions
RUN <<EOF
  ARCH=$(dpkg --print-architecture)

  # Install k9s
  curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin k9s
  chmod +x /usr/local/bin/k9s

  # Install stern
  curl -fsSL "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin stern
  chmod +x /usr/local/bin/stern

  # Install kubectx and kubens
  curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx" -o /usr/local/bin/kubectx
  curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens" -o /usr/local/bin/kubens
  chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens

  # Install kustomize
  curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin kustomize
  chmod +x /usr/local/bin/kustomize

  # Install kubecolor
  curl -fsSL "https://github.com/kubecolor/kubecolor/releases/download/${KUBECOLOR_VERSION}/kubecolor_${KUBECOLOR_VERSION#v}_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin kubecolor
  chmod +x /usr/local/bin/kubecolor

  # Install Argo CD CLI
  curl -fsSL "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-${ARCH}" -o /usr/local/bin/argocd
  chmod +x /usr/local/bin/argocd

  # Install kubeconform
  curl -fsSL "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-${ARCH}.tar.gz" | tar -xz -C /usr/local/bin kubeconform
  chmod +x /usr/local/bin/kubeconform

  # Install kubeseal
  curl -fsSL "https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION#v}-linux-${ARCH}.tar.gz" | tar -xz -C /usr/local/bin kubeseal
  chmod +x /usr/local/bin/kubeseal

  # Install talosctl
  curl -fsSL "https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/talosctl-linux-${ARCH}" -o /usr/local/bin/talosctl
  chmod +x /usr/local/bin/talosctl
EOF

# Install Infrastructure QA tools with pinned versions
RUN <<EOF
  ARCH=$(dpkg --print-architecture)

  # Install tflint
  curl -fsSL "https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_${ARCH}.zip" -o tflint.zip
  unzip tflint.zip && mv tflint /usr/local/bin/ && rm tflint.zip
  chmod +x /usr/local/bin/tflint

  # Install trivy - convert dpkg arch to trivy arch naming
  TRIVY_ARCH="64bit"
  if [ "$ARCH" = "arm64" ]; then
    TRIVY_ARCH="ARM64"
  fi
  curl -fsSL "https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/trivy_${TRIVY_VERSION#v}_Linux-${TRIVY_ARCH}.tar.gz" | tar -xz -C /usr/local/bin trivy
  chmod +x /usr/local/bin/trivy

  # Install hadolint
  HADOLINT_ARCH="x86_64"
  if [ "$ARCH" = "arm64" ]; then
    HADOLINT_ARCH="arm64"
  fi
  curl -fsSL "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-${HADOLINT_ARCH}" -o /usr/local/bin/hadolint
  chmod +x /usr/local/bin/hadolint


  # Install gitleaks - x86_64 only due to upstream release naming
  GITLEAKS_ARCH="x64"
  if [ "$ARCH" = "arm64" ]; then
    GITLEAKS_ARCH="arm64"
  fi
  curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION#v}_Linux_${GITLEAKS_ARCH}.tar.gz" | tar -xz -C /usr/local/bin gitleaks
  chmod +x /usr/local/bin/gitleaks
EOF

# Install modern CLI tools with pinned versions
RUN <<EOF
  ARCH=$(dpkg --print-architecture)

  # Install eza (modern ls) - x86_64 only due to upstream release naming
  if [ "$ARCH" = "amd64" ]; then
    curl -fsSL "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" | tar -xz -C /usr/local/bin
    chmod +x /usr/local/bin/eza
  else
    echo "Warning: eza not available for $ARCH architecture"
  fi

  # Install yq
  curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}" -o /usr/local/bin/yq
  chmod +x /usr/local/bin/yq

  # Install lazygit - x86_64 only due to upstream release naming
  LAZYGIT_ARCH="x86_64"
  if [ "$ARCH" = "arm64" ]; then
    LAZYGIT_ARCH="arm64"
  fi
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_${LAZYGIT_ARCH}.tar.gz" | tar -xz -C /usr/local/bin lazygit
  chmod +x /usr/local/bin/lazygit

  # Install Task (taskfile.dev)
  curl -fsSL "https://github.com/go-task/task/releases/download/${TASK_VERSION}/task_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin task
  chmod +x /usr/local/bin/task

  # Create symlinks for Ubuntu package names
  ln -sf /usr/bin/batcat /usr/local/bin/bat
  ln -sf /usr/bin/fdfind /usr/local/bin/fd
EOF

# Install Starship prompt with pinned version
RUN <<EOF
  ARCH=$(dpkg --print-architecture)
  # Convert dpkg arch to starship arch naming
  STARSHIP_ARCH="x86_64-unknown-linux-gnu"
  if [ "$ARCH" = "arm64" ]; then
    STARSHIP_ARCH="aarch64-unknown-linux-gnu"
  fi
  curl -fsSL "https://github.com/starship/starship/releases/download/${STARSHIP_VERSION}/starship-${STARSHIP_ARCH}.tar.gz" | tar -xz -C /usr/local/bin starship
  chmod +x /usr/local/bin/starship
EOF

# Create vscode user with sudo access for devcontainer
RUN <<EOF
  # Remove any existing user with the target UID (if exists)
  if getent passwd $USER_UID >/dev/null 2>&1; then
    existing_user=$(getent passwd $USER_UID | cut -d: -f1)
    userdel -r $existing_user 2>/dev/null || true
  fi

  # Remove any existing group with the target GID (if exists)
  if getent group $USER_GID >/dev/null 2>&1; then
    existing_group=$(getent group $USER_GID | cut -d: -f1)
    groupdel $existing_group 2>/dev/null || true
  fi

  # Create vscode user with explicit UID/GID for devcontainer compatibility
  groupadd -g $USER_GID $USERNAME
  useradd -m -l -u $USER_UID -g $USER_GID -s /usr/bin/fish -G sudo $USERNAME
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
  chmod 0440 /etc/sudoers.d/$USERNAME
EOF

# Set locale
RUN <<EOF
  locale-gen en_US.UTF-8
  update-locale LANG=en_US.UTF-8
EOF

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Set working directory
WORKDIR /home/$USERNAME
USER $USERNAME
ENV HOME=/home/$USERNAME

# Install Python CLI tools via pipx as vscode user
RUN <<EOF
  # Install Python development tools in isolated environments
  pipx install pre-commit
  pipx install poetry
  pipx install black
  pipx install ruff
EOF

# Configure Fish shell with settings from separate config files
RUN mkdir -p ~/.config/fish/conf.d ~/.config/fish/completions
COPY --chown=$USERNAME:$USERNAME fish/config.fish /home/$USERNAME/.config/fish/config.fish
COPY --chown=$USERNAME:$USERNAME fish/conf.d/ /home/$USERNAME/.config/fish/conf.d/

# Generate shell completions at build time for faster shell startup
RUN <<EOF
  # Generate kubectl completions
  kubectl completion fish > ~/.config/fish/completions/kubectl.fish

  # Generate helm completions
  helm completion fish > ~/.config/fish/completions/helm.fish

  # Generate task completions
  task --completion fish > ~/.config/fish/completions/task.fish

  # Generate talosctl completions
  talosctl completion fish > ~/.config/fish/completions/talosctl.fish

  # Generate argocd completions
  argocd completion fish > ~/.config/fish/completions/argocd.fish

  # Generate gh completions
  gh completion -s fish > ~/.config/fish/completions/gh.fish

  # Generate stern completions
  stern --completion fish > ~/.config/fish/completions/stern.fish

  # Generate k9s completions
  k9s completion fish > ~/.config/fish/completions/k9s.fish

  # Install terraform completions
  if ! terraform -install-autocomplete >/dev/null 2>&1; then
    echo "WARNING: terraform autocomplete installation failed; completions may be unavailable in this devcontainer." >&2
  fi
EOF

# Start fish shell by default
CMD ["/usr/bin/fish"]
