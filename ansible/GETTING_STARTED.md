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

For Windows hosts, ensure WinRM is configured. Run this on each Windows host as Administrator:

```powershell
# Download and run the Ansible WinRM configuration script
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"
(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file
```

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
- **Proxmox**: Automate VM management
- **Active Directory**: Configure domain controllers

**Note**: Kubernetes/Talos infrastructure is managed by Terraform and ArgoCD, not Ansible.

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
