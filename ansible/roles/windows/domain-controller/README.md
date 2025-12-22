# Domain Controller Role

This role configures Windows Server as an Active Directory Domain Controller.

## Requirements

- Windows Server 2016 or later
- Administrator privileges
- `microsoft.ad` collection installed

## Role Variables

```yaml
# Active Directory Domain Configuration
ad_domain_name: ad.example.com # FQDN of the domain
ad_netbios_name: EXAMPLE # NetBIOS name (max 15 characters)
ad_forest_mode: WinThreshold # Forest functional level
ad_domain_mode: WinThreshold # Domain functional level

# DNS Configuration
ad_install_dns: true # Install DNS with AD DS
ad_dns_forwarders: # DNS forwarders
  - 8.8.8.8
  - 8.8.4.4

# Safe Mode Password
ad_safe_mode_password: "SecurePassword123!" # Directory Services Restore Mode password
```

## Dependencies

None

## Example Playbook

```yaml
- name: Configure Domain Controllers
  hosts: domain_controllers
  roles:
    - role: windows/domain-controller
      vars:
        ad_domain_name: corp.example.com
        ad_netbios_name: CORP
```

## Notes

- The role is idempotent - it checks if AD is already configured before installation
- Server will reboot after domain installation
- Store `ad_safe_mode_password` in Ansible Vault for production use
