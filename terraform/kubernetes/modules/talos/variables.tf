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
  description = <<-EOT
    Talos image configuration for initial node deployment and optional updates:
    - version_base: The base Talos Linux version to deploy (e.g., "v1.9.0").
    - extensions_base: (Optional) System extensions to include in the base image (default: ["qemu-guest-agent"]).
    - platform_base: (Optional) Target platform for the base image (default: "metal").
    - version_update: (Optional) Talos version for updating nodes after initial deployment. If null, no update image is built.
    - extensions_update: (Optional) System extensions for the update image. If null, uses base extensions.
    - platform_update: (Optional) Target platform for the update image. If null, uses base platform.
    - proxmox_datastore: (Optional) Proxmox datastore ID where downloaded images are cached (default: "local").
    EOT
}

variable "talos_cluster" {
  type = object({
    endpoint            = optional(string, null)
    gateway             = string
    name                = string
    proxmox_cluster     = string
    talos_version       = string
    kubernetes_version  = string
    gateway_api_version = string
    extra_manifests     = optional(list(string))
    kubelet_extra_args  = optional(string, "")
    api_server          = optional(string)
  })
  description = <<-EOT
    Talos cluster configuration:
    - endpoint: (Optional) The Kubernetes API endpoint (e.g., "https://192.168.65.110:6443"). If not provided, derived from the primary endpoint node's IP.
    - gateway: The default network gateway for cluster nodes (e.g., "192.168.65.1").
    - name: The Talos cluster name used for identification and resource naming.
    - proxmox_cluster: The Proxmox cluster name where VMs will be provisioned.
    - talos_version: The Talos Linux version to deploy (e.g., "v1.9.0").
    - kubernetes_version: The Kubernetes version to deploy (e.g., "1.32.0").
    - gateway_api_version: The Kubernetes Gateway API version to enable (e.g., "v1").
    - extra_manifests: (Optional) Additional Kubernetes manifests (URLs or paths) to apply after cluster bootstrap.
    - kubelet_extra_args: (Optional) Custom kubelet extra arguments as a JSON string.
    - api_server: (Optional) Custom Kubernetes API server configuration as a JSON string.
    EOT
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
    Map of Talos nodes for cluster deployment where key is the node name (e.g., "control-1", "worker-1"):
    - host_node: Proxmox host node name where this VM will run (e.g., "hsp-proxmox0").
    - datastore_id: (Optional) Proxmox datastore ID for VM storage (default: "local-lvm").
    - machine_type: Node role, either "controlplane" or "worker".
    - ip: Static IP address for the node (e.g., "192.168.65.110").
    - mac_address: MAC address in format XX:XX:XX:XX:XX:XX (must be unique across nodes).
    - vm_id: Proxmox VM ID (numeric, must be unique across Proxmox cluster).
    - cpu: Number of CPU cores to allocate.
    - ram_dedicated: Amount of dedicated RAM in MB to allocate.
    - update: Whether to include this node in planned updates.
    - primary_endpoint: (Optional) Set to true for exactly one controlplane node - used as etcd bootstrap node (default: false).
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
  description = <<-EOT
    Cilium CNI configuration:
    - inline_manifest: Cilium HelmChart manifest content (typically generated via 'helm template') to be applied as an inline Kubernetes manifest.
    EOT
}
