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
    apt-utils \
    bash-completion \
    build-essential \
    bzip2 \
    ca-certificates \
    cmake \
    curl \
    dialog \
    dirmngr \
    dumb-init \
    fuse-overlayfs \
    gcc \
    git \
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
    python3 python3-cffi python3-pip python3-yaml python3-wheel \
    rsync \
    strace \
    sudo \
    tar \
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
    zsh \
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

# Install additional packages from additional repositories
RUN <<EOF
  apt-get update && apt-get install -y --no-install-recommends \
    gh \
    nodejs \
    postgresql-client \
    helm \
    terraform \
  && apt-get -y autoremove && apt-get -y autoclean && apt-get -y clean && rm -rf /var/lib/apt/lists/*
EOF

# Create vscode user with sudo access for devcontainer
RUN <<EOF
  if ! id -u $USERNAME >/dev/null 2>&1; then
    useradd -m -s /bin/zsh -G sudo $USERNAME
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
