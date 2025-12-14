# Base Windows Role

This role provides baseline configuration for Windows Server systems.

## Requirements

- Ansible 2.9+
- Target systems: Windows Server 2016+
- WinRM configured

## Role Variables

See `defaults/main.yml` for available variables.

## Dependencies

- ansible.windows collection

## Example Playbook

```yaml
- hosts: windows
  roles:
    - role: common/base-windows
```

## License

MIT

## Author

Home Infrastructure Team
