FROM ubuntu:noble
SHELL ["/bin/bash","-eux","-o","pipefail","-c"]

ARG ARCH=amd64
ARG NODE_VERSION=24.x
ARG USERNAME=vscode

# Install dependencies
RUN <<EOF
  apt update
  apt upgrade -y
  apt install -y --no-install-recommends \
    apt-transport-https \
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
    liblttng-ust1 \
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
    sq \
    strace \
    \
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
  ;
  apt -y autoremove
  apt -y autoclean
  rm -rf /var/lib/apt/lists/*
EOF

# Install GitHub CLI
RUN <<EOF
  mkdir -p -m 755 /etc/apt/keyrings
  out=$(mktemp) && curl -fsSL -o "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg
  cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  mkdir -p -m 755 /etc/apt/sources.list.d
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
EOF

# Configure nodesource - The installation will be done in later step
RUN <<EOF
  curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION | bash -
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
  apt update
  apt install --no-install-recommends -y \
    gh \
    nodejs \
    postgresql-client \
    helm \
    terraform \
  ;
  apt -y autoremove
  apt -y autoclean
  rm -rf /var/lib/apt/lists/*
EOF

# Create vscode user if it does not exist
RUN <<EOF
  if ! id -u $USERNAME >/dev/null 2>&1; then
    useradd -m -s /bin/zsh $USERNAME
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
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Set working directory
WORKDIR /home/$USERNAME
USER $USERNAME
ENV HOME=/home/$USERNAME
