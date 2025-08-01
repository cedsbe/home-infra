packer {
  required_plugins {
    windows-update = {
      version = "0.16.10"
      source  = "github.com/rgl/windows-update"
    }
    proxmox = {
      version = "1.2.1" # Issue with the CPU type in 1.2.2. See https://github.com/hashicorp/packer-plugin-proxmox/pull/308
      source  = "github.com/hashicorp/proxmox"
    }
  }
}
