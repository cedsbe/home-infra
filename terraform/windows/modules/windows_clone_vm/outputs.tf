output "vm_id" {
  description = "The ID of the created VM"
  value       = proxmox_virtual_environment_vm.windows_vm.id
}

output "vm_name" {
  description = "The name of the created VM"
  value       = proxmox_virtual_environment_vm.windows_vm.name
}

output "vm_fqdn" {
  description = "The FQDN of the VM (if searchdomain is provided)"
  value       = var.searchdomain != null ? "${var.vm_name}.${var.searchdomain}" : var.vm_name
}

output "vm_ipv4_address" {
  description = "The IPv4 address of the VM (if configured)"
  value       = var.ip_config != null && var.ip_config.ipv4 != null ? var.ip_config.ipv4.address : null
}

output "vm_ipv6_address" {
  description = "The IPv6 address of the VM (if configured)"
  value       = var.ip_config != null && var.ip_config.ipv6 != null ? var.ip_config.ipv6.address : null
}

output "vm_mac_addresses" {
  description = "The MAC addresses of the VM network interfaces"
  value       = proxmox_virtual_environment_vm.windows_vm.mac_addresses
}

output "vm_node_name" {
  description = "The Proxmox node where the VM is hosted"
  value       = proxmox_virtual_environment_vm.windows_vm.node_name
}

output "vm_cpu_cores" {
  description = "The number of CPU cores assigned to the VM"
  value       = var.cores
}

output "vm_memory_mb" {
  description = "The amount of memory in MB assigned to the VM"
  value       = var.memory
}

output "vm_disk_size_gb" {
  description = "The size of the main disk in GB"
  value       = var.disk_size
}

output "vm_tags" {
  description = "The tags assigned to the VM"
  value       = var.tags
}

output "vm_started" {
  description = "Whether the VM is started"
  value       = var.started
}

output "vm_connection_info" {
  description = "Connection information for the VM"
  value = {
    name  = var.vm_name
    ipv4  = var.ip_config != null && var.ip_config.ipv4 != null ? var.ip_config.ipv4.address : null
    ipv6  = var.ip_config != null && var.ip_config.ipv6 != null ? var.ip_config.ipv6.address : null
    fqdn  = var.searchdomain != null ? "${var.vm_name}.${var.searchdomain}" : var.vm_name
    node  = var.node_name
    vm_id = var.vm_id
  }
}
