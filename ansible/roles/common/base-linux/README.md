# Base Linux Role

This role provides baseline configuration for Linux systems.

## Requirements

- Ansible 2.9+
- Target systems: Debian/Ubuntu or RedHat/CentOS

## Role Variables

See `defaults/main.yml` for available variables.

## Dependencies

None

## Example Playbook

```yaml
- hosts: linux
  roles:
    - role: common/base-linux
```

## License

MIT

## Author

Home Infrastructure Team
