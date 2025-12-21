# Ansible Automation

This directory contains Ansible playbooks, roles, and inventory for managing Linux and Windows hosts in the home infrastructure.

## Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── requirements.yml         # Collections and roles dependencies
├── site.yml                 # Master playbook
├── inventory/              # Inventory files
│   ├── hosts.yml           # Main inventory (use this for sensitive IPs)
│   ├── hosts.yml.template  # Template for hosts.yml
│   ├── group_vars/         # Group-specific variables
│   │   ├── all/           # Variables for all hosts
│   │   ├── linux/         # Linux-specific variables
│   │   └── windows/       # Windows-specific variables
│   └── host_vars/         # Host-specific variables
├── playbooks/             # Task-specific playbooks
│   ├── linux/            # Linux playbooks
│   ├── windows/          # Windows playbooks
│   └── common/           # Cross-platform playbooks
├── roles/                # Custom roles
│   └── common/           # Shared roles
├── collections/          # Ansible collections (downloaded)
├── library/              # Custom modules
├── filter_plugins/       # Custom filters
└── logs/                 # Ansible logs (gitignored)
```

## Prerequisites

### Linux Hosts

- SSH access configured
- Python 3.6+ installed
- User with sudo privileges

### Windows Hosts

- SSH configured and enabled (OpenSSH Server)
- PowerShell 5.1+ or PowerShell Core
- User with Administrator privileges

## Quick Start

### 1. Install Dependencies

```bash
# Install required collections
ansible-galaxy collection install -r requirements.yml

# Install required roles (if any)
ansible-galaxy role install -r requirements.yml
```

### 2. Configure Inventory

Copy the template and customize for your environment:

```bash
cp inventory/hosts.yml.template inventory/hosts.yml
# Edit inventory/hosts.yml with your host details
```

### 3. Test Connectivity

```bash
# Test Linux hosts
ansible linux -m ping

# Test Windows hosts (using SSH)
ansible windows -m ping

# Test all hosts
ansible all -m ping
```

### 4. Run Playbooks

```bash
# Run the master playbook
ansible-playbook site.yml

# Run specific playbook
ansible-playbook playbooks/linux/update.yml

# Run with tags
ansible-playbook site.yml --tags "config"

# Run in check mode (dry-run)
ansible-playbook site.yml --check
```

## Managing Secrets

### Using Ansible Vault

```bash
# Create encrypted file
ansible-vault create inventory/group_vars/all/vault.yml

# Edit encrypted file
ansible-vault edit inventory/group_vars/all/vault.yml

# Encrypt existing file
ansible-vault encrypt inventory/group_vars/all/secrets.yml

# Decrypt file
ansible-vault decrypt inventory/group_vars/all/secrets.yml

# View encrypted file
ansible-vault view inventory/group_vars/all/vault.yml
```

### Vault Password File

Create `.vault_password` file with your vault password:

```bash
echo "your-vault-password" > .vault_password
chmod 600 .vault_password
```

This file is gitignored for security.

## Windows Configuration

### Enable SSH on Windows Hosts

Run these PowerShell commands on the Windows host to install and enable OpenSSH, configure the firewall, add your public key, and start the service:

```powershell
# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start and enable the service
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Allow SSH through the firewall
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
  -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow

# Create .ssh and add your public key (replace <public-key> and adjust user as needed)
$sshDir = "$env:USERPROFILE\.ssh"
New-Item -ItemType Directory -Path $sshDir -Force
Set-Content -Path "$sshDir\authorized_keys" -Value "<public-key>"
icacls $sshDir /inheritance:r
icacls $sshDir /grant "$($env:USERNAME):(R,W)"
icacls "$sshDir\authorized_keys" /grant "$($env:USERNAME):(R)"

# Restart sshd to apply changes
Restart-Service sshd
```

Optional: edit C:\ProgramData\ssh\sshd_config to harden settings (disable PasswordAuthentication if using keys) and restart sshd.

Inventory example (use SSH connection for Windows hosts):

```yaml
windows_host:
  ansible_host: 192.168.65.130
  ansible_user: Administrator
  ansible_connection: ssh
  ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

Test connectivity from your control host:

```bash
# Use the normal ping module (not win_ping) when using SSH
ansible windows -m ping
```

### Test Windows Connection

```bash
ansible windows -m win_ping
```

## Common Tasks

### Update All Linux Systems

```bash
ansible-playbook playbooks/linux/update.yml
```

### Install Software on Windows

```bash
ansible-playbook playbooks/windows/install-software.yml --extra-vars "package_name=git"
```

### Run Ad-Hoc Commands

```bash
# Linux: Check disk space
ansible linux -m shell -a "df -h"

# Windows: Check services
ansible windows -m win_shell -a "Get-Service | Where-Object {$_.Status -eq 'Running'}"
```

## Best Practices

1. **Use Roles**: Organize tasks into reusable roles
2. **Vault Secrets**: Never commit plaintext passwords or API keys
3. **Idempotency**: Ensure playbooks can be run multiple times safely
4. **Check Mode**: Test changes with `--check` before applying
5. **Tags**: Use tags for selective playbook execution
6. **Documentation**: Document variables and role dependencies
7. **Version Control**: Keep inventory templates, not actual host files
8. **Naming**: Use descriptive names for hosts, groups, and playbooks

## Integration with Home Infrastructure

This Ansible project integrates with the broader home-infra repository:

- **Terraform**: Can use Terraform outputs to generate dynamic inventory
- **Windows**: Can configure Windows Server VMs created by Packer

**Note**: Kubernetes/Talos and Proxmox infrastructure are managed exclusively by Terraform, not by Ansible.

## Troubleshooting

### Connection Issues

```bash
# Verbose output
ansible-playbook site.yml -vvv

# Test SSH connection
ssh -i ~/.ssh/id_rsa user@host

# Test Windows connection (via SSH)
ansible windows -m ping -vvv
```

### Common Windows Issues

- **Connection Timeout**: Verify OpenSSH Server is enabled and firewall allows it
- **Authentication Failed**: Check SSH keys or credentials in inventory

### Common Linux Issues

- **Permission Denied**: Check SSH key permissions (should be 600)
- **Sudo Password**: Use `--ask-become-pass` if sudo password required
- **Host Key Checking**: Set `host_key_checking = False` in ansible.cfg

## Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Windows Modules](https://docs.ansible.com/ansible/latest/collections/ansible/windows/)
- [Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
