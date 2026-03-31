variable "bridge" {
  description = "The network bridge."
  type        = string
}

variable "cdrom_drive_unattended_files_windows" {
  description = "The CD-ROM drive letter for the additional ISO files."
  type        = string
}

variable "cdrom_drive_virtio_windows" {
  description = "The CD-ROM drive letter for virtio drivers."
  type        = string
}

variable "win11_clone_vm_id" {
  description = "The VM ID of the Windows 11 base template to clone."
  type        = number

  validation {
    condition     = var.win11_clone_vm_id >= 100 && var.win11_clone_vm_id <= 999999999
    error_message = "VM ID must be a number between 100 and 999999999."
  }
}

variable "cores" {
  description = "The number of cores."
  type        = number
}

variable "disable_debug_breakpoints" {
  description = "Disable breakpoints."
  type        = bool
  default     = true
}

variable "disable_pre_sysprep_breakpoints" {
  description = "Disable breakpoints."
  type        = bool
  default     = true
}

variable "disk_size_gb" {
  description = "The disk size in GB."
  type        = number
}

variable "disk_storage" {
  description = "The disk storage pool."
  type        = string

  validation {
    condition     = length(var.disk_storage) > 0
    error_message = "Storage pool name must not be empty."
  }
}

variable "efi_storage" {
  description = "The EFI storage pool."
  type        = string

  validation {
    condition     = length(var.efi_storage) > 0
    error_message = "Storage pool name must not be empty."
  }
}

variable "full_clone" {
  description = "Enable full clone."
  type        = bool
  default     = true
}

variable "image_index" {
  description = "The image index map."
  type        = map(string)
}

variable "iso_storage" {
  description = "The ISO storage pool."
  type        = string

  validation {
    condition     = length(var.iso_storage) > 0
    error_message = "Storage pool name must not be empty."
  }
}

variable "memory" {
  description = "The memory size."
  type        = number
}

variable "proxmox_api_token" {
  description = "The Proxmox API user."
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "The Proxmox node."
  type        = string
}

variable "proxmox_username" {
  description = "The Proxmox API username."
  type        = string
}

variable "proxmox_url" {
  description = "The Proxmox API URL."
  type        = string
}

variable "sockets" {
  description = "The number of sockets."
  type        = number
}

variable "template" {
  description = "The Windows 11 edition template."
  type        = string

  validation {
    condition = (
      (var.template == "Pro") ||
      (var.template == "ProN") ||
      (var.template == "Enterprise") ||
      (var.template == "EnterpriseN") ||
      (var.template == "Education") ||
      (var.template == "EducationN")
    )
    error_message = "Invalid template name. Valid values: Pro, ProN, Enterprise, EnterpriseN, Education, EducationN."
  }
}

variable "virtio_win_iso" {
  description = "The VirtIO Windows ISO file."
  type        = string
}

variable "windows_iso" {
  description = "The Windows ISO file."
  type        = string
}

variable "winrm_password" {
  description = "The WinRM password."
  type        = string
  sensitive   = true
}

variable "winrm_username" {
  description = "The WinRM user."
  type        = string
}
