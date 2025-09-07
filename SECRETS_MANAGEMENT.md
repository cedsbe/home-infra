# Secrets Management with Git-Crypt

This repository uses [git-crypt](https://www.agwa.name/projects/git-crypt/) for secure secrets management. All sensitive files are automatically encrypted when committed to git and decrypted when checked out.

## 🔐 What's Encrypted

The following files are automatically encrypted with git-crypt:

- `*.secrets.auto.tfvars` - Terraform secrets (API tokens, passwords, keys)
- `backend.config` - Terraform backend configuration (may contain storage keys)
- `packer/**/.env` - Packer environment variables (Proxmox credentials, WinRM passwords)
- `terraform/**/.env` - Terraform environment variables (Cloudflare API tokens)

## 📋 Available Tasks

### Status and Information
```bash
task secrets:status                 # Show encryption status of all secrets files
task secrets:verify-templates       # Verify templates match actual secrets structure
```

### Setting Up Secrets
```bash
task secrets:create-from-templates  # Create secrets files from templates (for new setup)
task secrets:init-new-environment   # Complete setup for new environment
```

### Key Management
```bash
task secrets:export-key            # Export git-crypt key for backup (CRITICAL!)
task secrets:unlock KEYFILE=path   # Unlock repository with key file
task secrets:lock                  # Lock repository (remove encryption key)
```

## 🚀 Quick Start

### For New Repository Clone

If you're cloning this repository for the first time:

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/home-infra.git
   cd home-infra
   ```

2. **Check if you need the encryption key**
   ```bash
   task secrets:status
   ```

3. **Option A: You have the git-crypt key**
   ```bash
   task secrets:unlock KEYFILE=/path/to/your/backup/key
   task secrets:status  # Verify all files are decrypted
   ```

4. **Option B: Setting up a new environment (no existing key)**
   ```bash
   task secrets:init-new-environment
   # Edit the created files with your actual credentials
   # Commit the files (they'll be encrypted automatically)
   task secrets:export-key  # CRITICAL: Backup your key!
   ```

### For Existing Repository (Add New Secrets)

1. **Check current status**
   ```bash
   task secrets:status
   ```

2. **Add new secrets files** (if you have templates)
   ```bash
   task secrets:create-from-templates
   # Edit the new files with actual values
   git add .
   git commit -m "Add new secrets configuration"
   ```

3. **Backup your key** (if you haven't recently)
   ```bash
   task secrets:export-key
   ```

## 📁 File Structure

```
├── terraform/
│   ├── azure/
│   │   ├── azure.secrets.auto.tfvars      # 🔒 Encrypted - Azure credentials
│   │   ├── azure.secrets.auto.tfvars.template  # Safe template
│   │   └── backend.config                 # 🔒 Encrypted - State backend config
│   ├── kubernetes/
│   │   ├── proxmox.secrets.auto.tfvars    # 🔒 Encrypted - Proxmox credentials
│   │   └── backend.config                 # 🔒 Encrypted - State backend config
│   ├── cloudflare/
│   │   ├── .env                           # 🔒 Encrypted - Cloudflare API token
│   │   ├── cloudflare.secrets.auto.tfvars # 🔒 Encrypted - Zone IDs
│   │   └── backend.config                 # 🔒 Encrypted - State backend config
│   └── windows/
│       ├── proxmox.secrets.auto.tfvars    # 🔒 Encrypted - Proxmox credentials
│       └── backend.config                 # 🔒 Encrypted - State backend config
└── packer/
    └── windows_server_2025/
        └── .env                           # 🔒 Encrypted - Proxmox & WinRM credentials
```

## 🔑 Key Management

### Export Your Key (CRITICAL!)
```bash
task secrets:export-key
```

**Store the exported key in multiple secure locations:**
- Password manager (Bitwarden, 1Password, etc.)
- Encrypted cloud storage (separate from git repository)
- Encrypted USB drive (offline backup)
- Secure network storage (encrypted)

### Key Recovery
If you lose your git-crypt key but still have the repository:
1. Use template files to recreate the structure
2. Fill in your credentials from memory/other sources
3. Create a new git-crypt setup

## 🔒 Security Best Practices

### ✅ What's Safe
- **Template files** - These contain no secrets and show structure
- **Internal IP addresses** - Private networks (192.168.x.x, 10.x.x.x)
- **Internal domain names** - Local domains (homelab.local, ad.ghiot.be)
- **Configuration structure** - Non-sensitive infrastructure patterns

### ❌ What's Protected
- **API tokens and keys** - External service credentials
- **Passwords** - System and service passwords
- **Zone IDs** - Cloudflare zone identifiers
- **Storage keys** - Azure storage account keys
- **VM credentials** - Proxmox and Windows credentials

### 🛡️ Additional Security
- **Git-crypt uses AES-256** encryption
- **Files are encrypted at rest** in git history
- **Decryption requires the key file**
- **Multiple team members** can have different keys
- **Zero-knowledge sharing** via GPG integration possible

## 🚨 Emergency Procedures

### Lost Git-Crypt Key
1. **Check backup locations** for exported key files
2. **Use template files** to understand what credentials you need
3. **Recreate from memory/external sources** if possible
4. **Re-initialize git-crypt** with new key if necessary

### Suspected Key Compromise
1. **Rotate all credentials** in the secrets files
2. **Export new git-crypt key** with different name
3. **Update shared team keys** if applicable
4. **Review access logs** for any unauthorized usage

### Repository Migration
1. **Export git-crypt key** before any migration
2. **Test unlock process** on new clone
3. **Verify all secrets files** decrypt properly
4. **Update team documentation** with new procedures

## 📚 Additional Resources

- [Git-Crypt Documentation](https://www.agwa.name/projects/git-crypt/)
- [Git-Crypt GitHub Repository](https://github.com/AGWA/git-crypt)
- [AES-256 Encryption Information](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)

## 🤝 Team Collaboration

For team environments, consider:
- **GPG key integration** for individual team member access
- **Shared key storage** in secure team password manager
- **Key rotation procedures** for security compliance
- **Access audit trails** for compliance requirements

---

**Remember: The git-crypt key is like a master password. Treat it with the same security as your most sensitive credentials!**
