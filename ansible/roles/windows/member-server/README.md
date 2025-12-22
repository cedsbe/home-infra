# Member Server Role

This role joins Windows Server to an Active Directory domain as a member server.

## Requirements

- Windows Server 2016 or later
- Network connectivity to domain controllers
- `microsoft.ad` collection installed
- Valid domain admin credentials

## Role Variables

```yaml
# Active Directory Domain
ad_domain_name: ad.example.com # FQDN of the domain to join

# Domain Admin Credentials
ad_domain_admin_user: Administrator # Domain admin username
ad_domain_admin_password: "SecurePassword123!" # Domain admin password

# DNS Configuration (optional)
ad_dns_servers: # DNS servers (domain controllers)
  - 192.168.1.10
  - 192.168.1.11
```

## Dependencies

- Domain must already exist
- Domain controllers must be accessible

## Example Playbook

```yaml
- name: Configure Member Servers
  hosts: windows_members
  roles:
    - role: windows/member-server
      vars:
        ad_domain_name: corp.example.com
        ad_domain_admin_user: "CORP\\Administrator"
```

## Notes

- The role is idempotent - it checks domain membership before joining
- Server will reboot after joining the domain
- Store credentials in Ansible Vault for production use
- DNS servers will be automatically configured if provided
