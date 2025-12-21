# Ansible Project - Getting Started

This directory contains a complete Ansible automation setup for managing Linux and Windows hosts.

## Quick Start

### 1. Initial Setup

```bash
# From the project root, run the setup task
task ansible:setup
```

This will:

- Copy inventory template to `hosts.yml`
- Install required Ansible collections
- Create necessary directories

### 2. Configure Inventory

Edit `inventory/hosts.yml` with your actual host information:

```bash
vim inventory/hosts.yml
```

Replace placeholder IP addresses with your actual hosts.

### 3. Test Connectivity

```bash
# Test Linux hosts
task ansible:ping:linux

# Test Windows hosts
task ansible:ping:windows

# Test all hosts
task ansible:ping:all
```

### 4. Run Playbooks

```bash
# Run the master playbook
task ansible:run:site

# Update Linux systems
task ansible:update:linux

# Update Windows systems
task ansible:update:windows

# Run baseline configuration
task ansible:baseline
```

## Windows Host Setup

Windows hosts use SSH for Ansible connections. Run the following as Administrator on each Windows host to install and enable OpenSSH and prepare for key-based authentication:

```powershell
# Install and enable OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Open firewall for SSH
if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
  New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH SSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}

# Prepare authorized_keys for Administrator (or target user)
$sshDir = "$env:ProgramData\ssh"
New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
New-Item -ItemType File -Path "$sshDir\administrators_authorized_keys" -Force | Out-Null
# Place your public keys into administrators_authorized_keys (or the user's %USERPROFILE%\.ssh\authorized_keys)
```

In your inventory, set SSH connection variables, for example:

```yaml
ansible_user: Administrator
ansible_connection: ssh
ansible_ssh_private_key_file: /path/to/id_rsa
```

Use key-based authentication where possible; enable/require it in sshd_config for improved security.

## Managing Secrets

Use Ansible Vault for sensitive data:

```bash
# Create vault password file
echo "your-vault-password" > .vault_password
chmod 600 .vault_password

# Encrypt sensitive files
task ansible:vault:encrypt FILE=inventory/group_vars/all/vault.yml
```

## Available Tasks

View all available Ansible tasks:

```bash
task --list | grep ansible
```

## Project Structure

```
ansible/
├── ansible.cfg              # Configuration
├── requirements.yml         # Dependencies
├── site.yml                 # Master playbook
├── inventory/              # Host inventory
├── playbooks/              # Task playbooks
├── roles/                  # Reusable roles
└── Taskfile.yml            # Task automation
```

## Integration with Infrastructure

This Ansible project integrates with:

- **Windows**: Manage Windows Server VMs
- **Active Directory**: Configure domain controllers

**Note**: Kubernetes/Talos and Proxmox infrastructure are managed by Terraform and ArgoCD, not Ansible.

## Documentation

See `README.md` for complete documentation.

## Troubleshooting

Run validation to check configuration:

```bash
task ansible:validate
```

For verbose output:

```bash
task ansible:run:site -- -vvv
```
