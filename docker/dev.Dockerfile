FROM ubuntu:24.04
SHELL ["/bin/bash","-eux","-o","pipefail","-c"]

ARG NODE_VERSION=24.x
ARG USERNAME=vscode
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Europe/Brussels
ENV TZ=$TZ

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

# Add Fish shell PPA
RUN <<EOF
    add-apt-repository -y ppa:fish-shell/release-4
EOF

# Install additional packages from additional repositories
RUN <<EOF
  apt-get update && apt-get install -y --no-install-recommends \
    fish \
    gh \
    helm \
    kubectl \
    nodejs \
    packer \
    pipx \
    postgresql-client \
    terraform \
  && apt-get -y autoremove && apt-get -y autoclean && apt-get -y clean && rm -rf /var/lib/apt/lists/*
EOF

# Install Python CLI tools via pipx (isolated environments)
RUN <<EOF
  # Ensure pipx path is available
  pipx ensurepath

  # Install Python development tools in isolated environments
  pipx install pre-commit
  pipx install poetry
  pipx install black
  pipx install ruff
EOF

# Install Kubernetes ecosystem tools
RUN <<EOF
  ARCH=$(dpkg --print-architecture)
  # Install k9s
  K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin k9s

  # Install stern
  STERN_VERSION=$(curl -s https://api.github.com/repos/stern/stern/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -fsSL "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin stern

  # Install kubectx and kubens
  KUBECTX_VERSION=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx" -o /usr/local/bin/kubectx
  curl -fsSL "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens" -o /usr/local/bin/kubens
  chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens

  # Install kustomize
  curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
  mv kustomize /usr/local/bin/

  # Install kubecolor
  KUBECOLOR_VERSION=$(curl -s https://api.github.com/repos/kubecolor/kubecolor/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -fsSL "https://github.com/kubecolor/kubecolor/releases/download/${KUBECOLOR_VERSION}/kubecolor_${KUBECOLOR_VERSION#v}_linux_${ARCH}.tar.gz" | tar -xz -C /usr/local/bin kubecolor

  # Install Argo CD CLI
  ARGOCD_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -fsSL "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-${ARCH}" -o /usr/local/bin/argocd
  chmod +x /usr/local/bin/argocd

  # Install kubeconform
  KUBECONFORM_VERSION=$(curl -s https://api.github.com/repos/yannh/kubeconform/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -fsSL "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-${ARCH}.tar.gz" | tar -xz -C /usr/local/bin kubeconform

  # Install talosctl
  TALOS_VERSION=$(curl -s https://api.github.com/repos/siderolabs/talos/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -fsSL "https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/talosctl-linux-${ARCH}" -o /usr/local/bin/talosctl
  chmod +x /usr/local/bin/talosctl
EOF

# Install Infrastructure QA tools
RUN <<EOF
  ARCH=$(dpkg --print-architecture)
  # Install tflint
  curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

  # Install trivy
  TRIVY_VERSION=$(curl -s https://api.github.com/repos/aquasecurity/trivy/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -fsSL "https://github.com/aquasecurity/trivy/releases/download/${TRIVY_VERSION}/trivy_${TRIVY_VERSION#v}_Linux-64bit.tar.gz" | tar -xz -C /usr/local/bin trivy

  # Install hadolint
  HADOLINT_VERSION=$(curl -s https://api.github.com/repos/hadolint/hadolint/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -fsSL "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64" -o /usr/local/bin/hadolint
  chmod +x /usr/local/bin/hadolint
EOF

# Install modern CLI tools
RUN <<EOF
  ARCH=$(dpkg --print-architecture)
  # Install eza (modern ls)
  EZA_VERSION=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -fsSL "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" | tar -xz -C /usr/local/bin eza

  # Install yq
  YQ_VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}" -o /usr/local/bin/yq
  chmod +x /usr/local/bin/yq

  # Install lazygit
  LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz" | tar -xz -C /usr/local/bin lazygit

  # Create symlinks for Ubuntu package names
  ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
  ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
EOF

# Create vscode user with sudo access for devcontainer
RUN <<EOF
  if ! id -u $USERNAME >/dev/null 2>&1; then
    useradd -m -s /usr/bin/fish -G sudo $USERNAME
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
    chmod 0440 /etc/sudoers.d/$USERNAME
  fi
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

# Install Starship prompt
RUN <<EOF
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y
EOF

# Configure Fish with useful aliases and settings
RUN <<EOF
  # Create fish config directory
  mkdir -p ~/.config/fish/conf.d

  # Configure Starship prompt
  echo 'starship init fish | source' > ~/.config/fish/conf.d/starship.fish

  # Configure direnv
  echo 'direnv hook fish | source' > ~/.config/fish/conf.d/direnv.fish

  # Configure fzf key bindings
  echo 'fzf --fish | source' > ~/.config/fish/conf.d/fzf.fish

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
CONFIG
EOF
