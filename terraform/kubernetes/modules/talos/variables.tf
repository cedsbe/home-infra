variable "images" {
  type = object({
    version_base    = string
    extensions_base = optional(list(string), ["qemu-guest-agent"])
    platform_base   = optional(string, "metal")

    version_update    = optional(string, null)
    extensions_update = optional(list(string), null)
    platform_update   = optional(string, null)

    proxmox_datastore = optional(string, "local")
  })
  description = "Images configuration."
}

variable "talos_cluster" {
  type = object({
    endpoint        = optional(string, null)
    gateway         = string
    name            = string
    proxmox_cluster = string
    talos_version   = string
  })
  description = "Talos cluster configuration, including the endpoint, gateway, name, proxmox cluster, and Talos version."
}

variable "talos_nodes" {
  type = map(object({
    host_node        = string
    datastore_id     = optional(string, "local-lvm")
    machine_type     = string
    ip               = string
    mac_address      = string
    vm_id            = string
    cpu              = number
    ram_dedicated    = number
    update           = bool
    primary_endpoint = optional(bool, false)
  }))

  description = <<-EOT
    Map of nodes where the key is the node name and the value is an object containing:
    - host_node: The hostname of the proxmox host of the node.
    - datastore_id: (Optional) The ID of the datastore where the node will be stored. Default to 'local-lvm'.
    - machine_type: The type of the machine, either 'controlplane' or 'worker'.
    - ip: The IP address of the node.
    - mac_address: The MAC address of the node.
    - vm_id: The VM ID of the node.
    - cpu: The number of CPUs allocated to the node.
    - ram: The amount of RAM (in MB) allocated to the node.
    - update: A boolean indicating whether the node should be updated.
    - primary_endpoint: (Optional) A boolean indicating whether the node is the one used for etcd bootstrap. Default to false.
    EOT

  #region validations
  validation {
    condition     = length(keys(var.talos_nodes)) > 0
    error_message = "At least one node must be defined."
  }

  validation {
    condition     = alltrue([for node in values(var.talos_nodes) : can(regex("^[a-z0-9-]+$", node.host_node))])
    error_message = "Node names must be lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition     = alltrue([for node in values(var.talos_nodes) : can(regex("^[0-9A-F]{2}(:[0-9A-F]{2}){5}$", node.mac_address))])
    error_message = "MAC addresses must be in the format of 00:00:00:00:00:00."
  }

  validation {
    condition     = alltrue([for node in values(var.talos_nodes) : can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", node.ip))])
    error_message = "IP addresses must be in the format of x.x.x.x where x is a number between 0 and 255."
  }

  validation {
    condition     = alltrue([for node in values(var.talos_nodes) : can(regex("^[0-9]+$", node.vm_id))])
    error_message = "VM IDs must be numeric."
  }

  validation {
    condition     = alltrue([for node in values(var.talos_nodes) : can(regex("^(controlplane|worker)$", node.machine_type))])
    error_message = "Machine type must be either 'controlplane' or 'worker'."
  }

  validation {
    condition     = length(keys({ for node in values(var.talos_nodes) : node.mac_address => true })) == length(values(var.talos_nodes))
    error_message = "MAC addresses must be unique."
  }

  validation {
    condition     = length(keys({ for node in values(var.talos_nodes) : node.vm_id => true })) == length(values(var.talos_nodes))
    error_message = "VM IDs must be unique."
  }

  validation {
    condition     = length(keys({ for node in values(var.talos_nodes) : node.ip => true })) == length(values(var.talos_nodes))
    error_message = "IP addresses must be unique."
  }

  validation {
    condition     = length([for node in values(var.talos_nodes) : node.primary_endpoint if node.primary_endpoint == true]) == 1
    error_message = "One and only one node must be marked as bootstrap."
  }

  #endregion validations

}

variable "cilium" {
  type = object({
    inline_manifest = string
  })
  description = "Cilium configuration"
}
