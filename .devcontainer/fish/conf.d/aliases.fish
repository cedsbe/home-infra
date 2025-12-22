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
