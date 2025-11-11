variable "proxmox" {
  type = object({
    cluster_name = string
    endpoint     = string
    insecure     = bool
  })
  description = <<-EOT
    Proxmox cluster configuration for CSI plugin authentication:
    - cluster_name: Proxmox cluster identifier used as region in CSI config (e.g., "homelab").
    - endpoint: Proxmox API endpoint URL (e.g., "https://192.168.65.1:8006").
    - insecure: Whether to skip TLS certificate verification. Set to true only for self-signed certificates in dev/lab environments.
    EOT
}
