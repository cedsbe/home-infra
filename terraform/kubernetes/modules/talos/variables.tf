variable "images" {
  type = object({
    version_base    = string
    extensions_base = optional(list(string), ["qemu-guest-agent"])
    platform_base   = optional(string, "metal")

    version_update    = string
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
    dns_servers         = optional(list(string), ["192.168.65.150", "192.168.65.30", "192.168.65.40"])
    search_domains      = optional(list(string), ["ad.ghiot.be", "ghiot.be"])
    oidc_issuer_url     = optional(string, null)
    oidc_client_id      = optional(string, null)
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
    - dns_servers: (Optional) List of DNS server IP addresses (default: ["192.168.65.150", "192.168.65.30", "192.168.65.40"]).
    - search_domains: (Optional) List of DNS search domains (default: ["ad.ghiot.be", "ghiot.be"]).
    - oidc_issuer_url: OIDC issuer URL for Kubernetes API server authentication.
    - oidc_client_id: OIDC client ID for Kubernetes API server authentication.

    Note:
    - If OIDC fields are set, the module will generate a kubeconfig with an exec credential plugin for OIDC authentication. Ensure that the OIDC provider is properly configured and accessible by cluster users.
    - To use the generated OIDC kubeconfig, users must have the kubectl oidc-login (kubelogin) plugin installed (for example, via krew: 'kubectl krew install oidc-login'; see https://github.com/int128/kubelogin for other installation options).
    - Adding 192.168.65.150 (Adguard DNS) as primary DNS server allows Talos nodes to resolve the running container in the cluster, like Pocket-Id, which is required for the OIDC.

    OIDC Context Behavior:
    - When OIDC is enabled, the generated kubeconfig sets the current-context to "oidc-context", making OIDC the default authentication method.
    - The original Talos admin context remains available in the kubeconfig for emergency access or initial RBAC setup, but is not the default.
    - To view all available contexts (including the admin context), use: kubectl config get-contexts
    - To switch to the admin context, use: kubectl config use-context <context-name> (where <context-name> is the admin context name from the list, typically named "admin@<cluster-name>")
    - To switch back to OIDC context, use: kubectl config use-context oidc-context
    EOT

  validation {
    condition     = var.talos_cluster.oidc_issuer_url == null || can(regex("^https://", var.talos_cluster.oidc_issuer_url))
    error_message = "OIDC issuer URL must use HTTPS for secure token exchange. Use null to disable OIDC."
  }
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
    interface_name   = optional(string, "ens18")
    cidr_mask        = optional(number, null)
    gateway          = optional(string, null)
    storage_size_gb  = optional(number, 20)
  }))

  description = <<-EOT
    ## Talos Node Configuration

    Map of Talos nodes for cluster deployment where key is the node name (e.g., `control-1`, `worker-1`).

    ### Required Fields

    - **host_node**: Proxmox host node name where this VM will run (e.g., `hsp-proxmox0`).
    - **machine_type**: Node role, either `controlplane` or `worker`.
    - **ip**: Static IP address for the node (e.g., `192.168.65.110`).
    - **mac_address**: MAC address in format `XX:XX:XX:XX:XX:XX` (must be unique across nodes).
    - **vm_id**: Proxmox VM ID (numeric, must be unique across Proxmox cluster).
    - **cpu**: Number of CPU cores to allocate.
    - **ram_dedicated**: Amount of dedicated RAM in MB to allocate.
    - **update**: Whether to use the update image for this node (see [UPDATE MECHANISM](#update-mechanism) below).

    ### Optional Fields

    - **datastore_id**: Proxmox datastore ID for VM storage (default: `local-lvm`).
    - **primary_endpoint**: Set to `true` for exactly one controlplane node - used as etcd bootstrap node (default: `false`).
    - **interface_name**: Network interface name (default: `ens18`). Used for Talos 1.12 LinkConfig.
    - **cidr_mask**: CIDR notation mask for the IP (default: `24` for `/24`). Used for Talos 1.12 LinkConfig.
    - **gateway**: Default gateway IP address. Falls back to `talos_cluster.gateway` if not set. Used for Talos 1.12 LinkConfig.
    - **storage_size_gb**: Size of the VM storage in GB (default: `20`).

    ## UPDATE MECHANISM - Manual Rolling Updates

    The `update` field controls which Talos boot image is used during node provisioning:
    - `update = false`: Uses `talos_version` (initial deployment version from talos_base image)
    - `update = true`: Uses `talos_update_version` (upgrade version from talos_update image)

    ### Validation (Using terraform_data)

    A `terraform_data` resource named `validate_update_configuration` runs during planning to detect invalid update configurations early:
    - If any node has `update=true` AND `talos_update_version` is null → **PLAN FAILS** with clear error
    - This prevents broken configurations from reaching the apply phase
    - The error message shows exactly which nodes require updates and what to fix

    **IMPORTANT**: You must set `talos_update_version` in `components_versions.auto.tfvars` before setting any node's `update=true`. The validation will catch this mismatch.

    ### Rolling Update Procedure

    #### 1. Prepare for Updates

    - Decide which Talos version to upgrade to
    - Set the desired version in `components_versions.auto.tfvars`:
      ```
      talos_update_version = "v1.12.0"  # Must be > talos_version
      ```
    - Run: `terraform plan`
    - Verify no unexpected changes (should only show new ISO download)

    #### 2. Update Nodes in Sequence (One or Two at a Time)

    Update nodes one or two at a time, but **keep the `update=true` flag set** for already-updated nodes:

    - Set `update=true` for the first node:
      ```
      "hsv-kwork0" = {
        ...
        update = true    # ← Change from false to true
      }
      ```
    - Run: `terraform plan` and `terraform apply`
    - Wait for the node to boot and report `Ready` status: `talosctl health -n <node-ip> --client-configuration output/talos-config.yaml`
    - Once ready, set `update=true` for the next node while keeping the first one's flag as `true`:
      ```
      "hsv-kwork0" = {
        ...
        update = true    # ← Stays true
      }
      "hsv-kwork1" = {
        ...
        update = true    # ← Change from false to true
      }
      ```
    - Repeat: `terraform plan` and `terraform apply`
    - Continue until all nodes have `update=true` and have completed their updates

    #### 3. Update talos_version

    Once all nodes are updated and healthy:
    - Update `talos_version` in `components_versions.auto.tfvars` to match `talos_update_version`:
      ```
      talos_version = "v1.12.0"  # Now same as talos_update_version
      ```
    - Run: `terraform plan` and `terraform apply`

    #### 4. Reset Update Flags and Clean Up

    - Set `update=false` for all nodes:
      ```
      "hsv-kctrl0" = { ... update = false }
      "hsv-kwork0" = { ... update = false }
      "hsv-kwork1" = { ... update = false }
      ```
    - Set `talos_update_version = null` in `components_versions.auto.tfvars`
    - Run: `terraform apply`
    - This locks in the new stable state and prevents accidental re-updates

    ### Example: Rolling Update from v1.11.3 to v1.12.0

    **Initial state**:
    ```
    # components_versions.auto.tfvars
    talos_version = "v1.11.3"
    talos_update_version = "v1.12.0"

    # main.tf
    talos_nodes = {
      "hsv-kctrl0" = { ... update = false }
      "hsv-kwork0" = { ... update = false }
      "hsv-kwork1" = { ... update = false }
    }
    ```

    **Step 1**: Update first worker
    ```
    talos_nodes = {
      "hsv-kctrl0" = { ... update = false }
      "hsv-kwork0" = { ... update = true }   # ← Set to true
      "hsv-kwork1" = { ... update = false }
    }
    terraform apply
    # Wait for node recovery (5-10 minutes)
    talosctl health -n 192.168.65.120
    ```

    **Step 2**: Update second worker (keep first one's flag as `true`)
    ```
    talos_nodes = {
      "hsv-kctrl0" = { ... update = false }
      "hsv-kwork0" = { ... update = true }   # ← Stays true
      "hsv-kwork1" = { ... update = true }   # ← Set to true
    }
    terraform apply
    # Wait for node recovery
    ```

    **Step 3**: Update control plane
    ```
    talos_nodes = {
      "hsv-kctrl0" = { ... update = true }   # ← Set to true
      "hsv-kwork0" = { ... update = true }   # ← Stays true
      "hsv-kwork1" = { ... update = true }   # ← Stays true
    }
    terraform apply
    # Wait for node recovery
    # Verify etcd health: talosctl etcd status -n 192.168.65.110
    ```

    **Step 4**: Update talos_version
    ```
    # All nodes now running v1.12.0, update the base version
    # In components_versions.auto.tfvars:
    talos_version = "v1.12.0"
    # In main.tf (all still have update=true, they'll be re-provisioned)
    terraform apply
    ```

    **Step 5**: Finalize
    ```
    # Set all update flags to false and clear update version
    talos_nodes = {
      "hsv-kctrl0" = { ... update = false }
      "hsv-kwork0" = { ... update = false }
      "hsv-kwork1" = { ... update = false }
    }
    # In components_versions.auto.tfvars:
    talos_update_version = null
    terraform apply
    ```

    ## Important Warnings

    ⚠️ **CLUSTER STABILITY**: Updating all nodes simultaneously or too many at once **WILL** cause loss of quorum and cluster downtime. Always update one node (maximum 2-3 workers if separate from control plane) at a time.

    ⚠️ **CONTROL PLANE PRIORITY**: Update control plane nodes one at a time **ONLY**. Losing 2+ control plane nodes = lost quorum = dead cluster.

    ⚠️ **MONITOR PROGRESS**: Always verify node health after updates using:
    ```
    talosctl health -n <node-ip> --client-configuration output/talos-config.yaml
    ```
    Wait for `Ready` status before updating next node.

    ⚠️ **VERSION MISMATCH**: Ensure `talos_update_version >= talos_version`. Updates are for upgrading or same-version refreshes, never downgrading.

    ⚠️ **BACKUP STATE**: Keep a backup of `terraform.tfstate` before large updates:
    ```
    cp terraform.tfstate terraform.tfstate.backup
    ```

    ⚠️ **ETCD HEALTH**: For control plane updates, verify etcd cluster remains healthy:
    ```
    talosctl etcd status -n <primary-control-plane-ip>
    ```
    Should show all members as `Leader` or `Follower`, no `Unknown`.

    ## Troubleshooting

    **If a node fails to update**:
    - Check Proxmox console for boot errors
    - Verify the ISO was downloaded: `ls -la /var/lib/vz/template/iso/` on Proxmox node
    - Manually reboot if needed: `talosctl reboot -n <node-ip>`
    - Restore previous state: Set `update=false` and re-apply

    **If cluster becomes unhealthy**:
    - Check all nodes are booted: `talosctl get nodes`
    - Check control plane: `talosctl health` (should show nodes as `Ready`)
    - May need to rollback by reverting `talos_update_version` and applying again
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
