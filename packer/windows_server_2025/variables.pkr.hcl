variable "bridge" {
  description = "The network bridge."
  type        = string
}

variable "cdrom_drive_unattended_files_windows" {
  description = "The CD-ROM drive letter for the additional ISO files."
  type        = string
}

variable "cdrom_drive_unattended_files_winre" {
  description = "The CD-ROM drive letter for the additional ISO files."
  type        = string
}

variable "cdrom_drive_virtio_windows" {
  description = "The CD-ROM drive letter for virtio drivers."
  type        = string
}

variable "cdrom_drive_virtio_winre" {
  description = "The CD-ROM drive letter for virtio drivers."
  type        = string
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
}

variable "efi_storage" {
  description = "The EFI storage pool."
  type        = string
}

variable "image_index" {
  description = "The image index map."
  type        = map(string)
}

variable "iso_storage" {
  description = "The ISO storage pool."
  type        = string
}

variable "memory" {
  description = "The memory size."
  type        = number
}

variable "proxmox_api_token" {
  description = "The Proxmox API user."
  type        = string
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
  description = "The Windows Server template."
  type        = string

  validation {
    condition = (
      (var.template == "StdCore") ||
      (var.template == "StdDesktop") ||
      (var.template == "DcCore") ||
      (var.template == "DcDesktop")
    )
    error_message = "Invalid template name."
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
}

variable "winrm_username" {
  description = "The WinRM user."
  type        = string
}