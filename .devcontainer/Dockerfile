FROM ubuntu:24.04
SHELL ["/bin/bash","-eux","-o","pipefail","-c"]

ARG NODE_VERSION=24.x
ARG USERNAME=vscode
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Europe/Brussels
ENV TZ=$TZ

# Tool versions - update these periodically or use Renovate
ARG K9S_VERSION=v0.32.7
ARG STERN_VERSION=v1.31.0
ARG KUBECTX_VERSION=v0.9.5
ARG KUSTOMIZE_VERSION=v5.5.0
ARG KUBECOLOR_VERSION=v0.4.0
ARG ARGOCD_VERSION=v2.13.2
ARG KUBECONFORM_VERSION=v0.7.1
ARG TALOS_VERSION=v1.9.2
ARG TFLINT_VERSION=v0.54.0
ARG TRIVY_VERSION=v0.58.1
ARG HADOLINT_VERSION=v2.12.0
ARG EZA_VERSION=v0.20.14
ARG YQ_VERSION=v4.44.6
ARG LAZYGIT_VERSION=v0.44.1
ARG TASK_VERSION=v3.40.1
ARG STARSHIP_VERSION=v1.21.1

# Install dependencies
RUN <<EOF
  apt-get update && apt-get -y upgrade && \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
  apt-get install -y --no-install-recommends \
    ansible \
    ansible-lint \
    apt-utils \
    bash-completion \
    bat \
    build-essential \
    bzip2 \
    ca-certificates \
    cmake \
    curl \
    dialog \
    dirmngr \
    direnv \
    dumb-init \
    fd-find \
    fuse-overlayfs \
    fzf \
    gcc \
    git \
    git-delta \
    gnupg \
    gnupg2 \
    htop \
    init-system-helpers \
    iproute2 \
    jq \
    less \
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
    locales \
    lsb-release \
    lsof \
    man-db \
    manpages \
    nano \
    ncdu \
    net-tools \
    netbase \
    openssh-client \
    pinentry-curses \
    pipx \
    pkg-config \
    podman \
    procps \
    psmisc \
    python3 python3-cffi python3-pip python3-venv python3-yaml python3-wheel \
    ripgrep \
    rsync \
    software-properties-common \
    strace \
    sudo \
    tar \
    tldr \
    tmux \
    tree \
    tzdata \
    unzip \
    util-linux \
    vim \
    wget \
    which \
    xz-utils \
    yamllint \
    zip \
    zlib1g \
  && apt-get -y autoremove && apt-get -y autoclean && apt-get -y clean && rm -rf /var/lib/apt/lists/*
EOF

# Install GitHub CLI
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

# Install cspell globally via npm
RUN <<EOF
  npm install -g cspell
EOF

# Install Kubernetes ecosystem tools with pinned versions
RUN <<EOF
  ARCH=$(dpkg --print-architecture)

  # Install k9s
  curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin k9s

  # Install stern
  curl -fsSL "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin stern

  # Install kubectx and kubens
  curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx" -o /usr/local/bin/kubectx
  curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens" -o /usr/local/bin/kubens
  chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens

  # Install kustomize
  curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin kustomize

  # Install kubecolor
  curl -fsSL "https://github.com/kubecolor/kubecolor/releases/download/${KUBECOLOR_VERSION}/kubecolor_${KUBECOLOR_VERSION#v}_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin kubecolor

  # Install Argo CD CLI
  curl -fsSL "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-${ARCH}" -o /usr/local/bin/argocd
  chmod +x /usr/local/bin/argocd

  # Install kubeconform
  curl -fsSL "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-${ARCH}.tar.gz" | tar -xz -C /usr/local/bin kubeconform

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

  # Install trivy
  curl -fsSL "https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/trivy_${TRIVY_VERSION#v}_Linux-64bit.tar.gz" | tar -xz -C /usr/local/bin trivy

  # Install hadolint
  curl -fsSL "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64" -o /usr/local/bin/hadolint
  chmod +x /usr/local/bin/hadolint
EOF

# Install modern CLI tools with pinned versions
RUN <<EOF
  ARCH=$(dpkg --print-architecture)

  # Install eza (modern ls) - x86_64 only due to upstream release naming
  if [ "$ARCH" = "amd64" ]; then
    curl -fsSL "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" | tar -xz -C /usr/local/bin
  else
    echo "Warning: eza not available for $ARCH architecture"
  fi

  # Install yq
  curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}" -o /usr/local/bin/yq
  chmod +x /usr/local/bin/yq

  # Install lazygit - x86_64 only due to upstream release naming
  if [ "$ARCH" = "amd64" ]; then
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz" | tar -xz -C /usr/local/bin lazygit
  else
    echo "Warning: lazygit not available for $ARCH architecture"
  fi

  # Install Task (taskfile.dev)
  curl -fsSL "https://github.com/go-task/task/releases/download/${TASK_VERSION}/task_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin task

  # Create symlinks for Ubuntu package names (may already exist, hence || true)
  ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
  ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
EOF

# Install Starship prompt with pinned version
RUN <<EOF
  curl -fsSL "https://github.com/starship/starship/releases/download/${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz" | tar -xz -C /usr/local/bin starship
  chmod +x /usr/local/bin/starship
EOF

# Create vscode user with sudo access for devcontainer
RUN <<EOF
  # Remove any existing user with UID 1000 (if exists)
  if getent passwd 1000 >/dev/null 2>&1; then
    existing_user=$(getent passwd 1000 | cut -d: -f1)
    userdel -r $existing_user 2>/dev/null || true
  fi

  # Remove any existing group with GID 1000 (if exists)
  if getent group 1000 >/dev/null 2>&1; then
    existing_group=$(getent group 1000 | cut -d: -f1)
    groupdel $existing_group 2>/dev/null || true
  fi

  # Create vscode user with explicit UID/GID 1000 for devcontainer compatibility
  groupadd -g 1000 $USERNAME
  useradd -m -u 1000 -g 1000 -s /usr/bin/fish -G sudo $USERNAME
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
ENV TZ=Europe/Brussels

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

# Configure Fish with useful aliases and settings
RUN <<EOF
  # Create fish config directory
  mkdir -p ~/.config/fish/conf.d

  # Configure Starship prompt
  echo 'starship init fish | source' > ~/.config/fish/conf.d/starship.fish

  # Configure direnv
  echo 'direnv hook fish | source' > ~/.config/fish/conf.d/direnv.fish

  # Configure fzf key bindings (apt version uses different paths)
  cat > ~/.config/fish/conf.d/fzf.fish << 'FZF'
# Source fzf key bindings if available
if test -f /usr/share/doc/fzf/examples/key-bindings.fish
  source /usr/share/doc/fzf/examples/key-bindings.fish
  fzf_key_bindings
end
FZF

  # Create aliases file
  cat > ~/.config/fish/conf.d/aliases.fish << 'ALIASES'
# Modern CLI aliases
alias ls 'eza --icons'
alias ll 'eza -l --icons'
alias la 'eza -la --icons'
alias lt 'eza --tree --icons'
alias cat 'batcat --style=plain'

# Git aliases
alias g 'git'
alias gs 'git status'
alias ga 'git add'
alias gc 'git commit'
alias gp 'git push'
alias gl 'git pull'
alias gd 'git diff'
alias lg 'lazygit'

# Kubernetes aliases with kubecolor
alias kubectl 'kubecolor'
alias k 'kubecolor'
alias kx 'kubectx'
alias kns 'kubens'
alias kgp 'kubecolor get pods'
alias kgs 'kubecolor get svc'
alias kgn 'kubecolor get nodes'

# Infrastructure aliases
alias tf 'terraform'
alias tfi 'terraform init'
alias tfp 'terraform plan'
alias tfa 'terraform apply'
alias az 'azure-cli'

# Ansible aliases
alias ap 'ansible-playbook'
alias av 'ansible-vault'
ALIASES

  # Enable Fish features
  cat > ~/.config/fish/config.fish << 'CONFIG'
# Enable VI mode (optional, comment out if you prefer emacs mode)
# fish_vi_key_bindings

# Set greeting
set -g fish_greeting

# Add local bin to PATH
fish_add_path ~/.local/bin

# kubectl completion
kubectl completion fish | source

# terraform completion
terraform -install-autocomplete 2>/dev/null || true

# task completion
task --completion fish | source

CONFIG
EOF

# Start fish shell by default
CMD ["/usr/bin/fish"]
