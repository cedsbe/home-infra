variable "vm_name" {
  description = "The name of the virtual machine"
  type        = string
}

variable "vm_id" {
  description = "The VM ID for the new VM"
  type        = number

  validation {
    condition     = var.vm_id >= 100 && var.vm_id <= 999999999
    error_message = "VM ID must be a number between 100 and 999999999."
  }
}

variable "clone_vm_id" {
  description = "The VM ID of the template to clone from"
  type        = number

  validation {
    condition     = var.clone_vm_id >= 100 && var.clone_vm_id <= 999999999
    error_message = "Clone VM ID must be a number between 100 and 999999999."
  }
}

variable "node_name" {
  description = "The name of the Proxmox node where the VM will be created"
  type        = string
}

variable "datastore" {
  description = "The datastore where the VM disks will be stored"
  type        = string
  default     = "local-lvm"
}

variable "memory" {
  description = "The amount of memory in MB allocated to the VM"
  type        = number
  default     = 4096

  validation {
    condition     = var.memory >= 1024 && var.memory <= 131072
    error_message = "Memory must be between 1024 MB (1 GB) and 131072 MB (128 GB)."
  }
}

variable "cores" {
  description = "The number of CPU cores allocated to the VM"
  type        = number
  default     = 2

  validation {
    condition     = var.cores >= 1 && var.cores <= 64
    error_message = "Cores must be between 1 and 64."
  }
}

variable "sockets" {
  description = "The number of CPU sockets"
  type        = number
  default     = 1

  validation {
    condition     = var.sockets >= 1 && var.sockets <= 4
    error_message = "Sockets must be between 1 and 4."
  }
}

variable "disk_size" {
  description = "The size of the main disk in GB"
  type        = number
  default     = 80

  validation {
    condition     = var.disk_size >= 40 && var.disk_size <= 2048
    error_message = "Disk size must be between 40 GB and 2048 GB."
  }
}

variable "network_bridge" {
  description = "The network bridge to connect the VM to"
  type        = string
  default     = "vmbr0"
}

variable "network_vlan" {
  description = "The VLAN tag for the network interface (optional)"
  type        = number
  default     = null

  validation {
    condition     = var.network_vlan == null || (var.network_vlan >= 1 && var.network_vlan <= 4094)
    error_message = "VLAN must be between 1 and 4094 or null."
  }
}

variable "ip_config" {
  description = "IP configuration for the VM"
  type = object({
    ipv4 = optional(object({
      address = string
      gateway = string
    }), null)
    ipv6 = optional(object({
      address = string
      gateway = string
    }), null)
  })
  default = null
}

variable "nameservers" {
  description = "List of DNS nameservers"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "searchdomain" {
  description = "Search domain for DNS"
  type        = string
  default     = null
}

variable "user_account" {
  description = "User account configuration"
  type = object({
    username = string
    password = string
  })
  sensitive = true
}

variable "ssh_keys" {
  description = "List of SSH public keys to add to the VM"
  type        = list(string)
  default     = []
}

variable "startup_order" {
  description = "The startup order of the VM"
  type        = number
  default     = null

  validation {
    condition     = var.startup_order == null || (var.startup_order >= 0 && var.startup_order <= 999)
    error_message = "Startup order must be between 0 and 999 or null."
  }
}

variable "startup_delay" {
  description = "The startup delay in seconds"
  type        = number
  default     = null

  validation {
    condition     = var.startup_delay == null || (var.startup_delay >= 0 && var.startup_delay <= 3600)
    error_message = "Startup delay must be between 0 and 3600 seconds or null."
  }
}

variable "protection" {
  description = "Enable VM protection (prevents accidental deletion)"
  type        = bool
  default     = false
}

variable "start_on_boot" {
  description = "Start VM automatically on boot"
  type        = bool
  default     = false
}

variable "started" {
  description = "Start the VM after creation"
  type        = bool
  default     = true
}

variable "tags" {
  description = "List of tags to assign to the VM"
  type        = list(string)
  default     = ["windows", "server-2025"]
}

variable "description" {
  description = "Description of the VM"
  type        = string
  default     = "Windows Server 2025 VM created with Terraform"
}

variable "machine_type" {
  description = "The machine type for the VM"
  type        = string
  default     = "q35"

  validation {
    condition     = contains(["pc", "q35"], var.machine_type)
    error_message = "Machine type must be either 'pc' or 'q35'."
  }
}

variable "bios" {
  description = "The BIOS type for the VM"
  type        = string
  default     = "ovmf"

  validation {
    condition     = contains(["seabios", "ovmf"], var.bios)
    error_message = "BIOS must be either 'seabios' or 'ovmf'."
  }
}

variable "tpm_enabled" {
  description = "Enable TPM for the VM (required for Windows 11/Server 2025)"
  type        = bool
  default     = true
}

variable "tpm_version" {
  description = "TPM version to use"
  type        = string
  default     = "v2.0"

  validation {
    condition     = contains(["v1.2", "v2.0"], var.tpm_version)
    error_message = "TPM version must be either 'v1.2' or 'v2.0'."
  }
}

variable "efi_storage_pool" {
  description = "Storage pool for EFI disk"
  type        = string
  default     = "local-lvm"
}

variable "scsi_controller" {
  description = "The SCSI controller type"
  type        = string
  default     = "virtio-scsi-single"

  validation {
    condition = contains([
      "lsi", "lsi53c810", "virtio-scsi-pci", "virtio-scsi-single",
      "megasas", "pvscsi"
    ], var.scsi_controller)
    error_message = "Invalid SCSI controller type."
  }
}
