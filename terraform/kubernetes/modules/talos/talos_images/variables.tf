variable "talos_image_base" {
  type = object({
    version         = string
    extensions      = optional(list(string), ["qemu-guest-agent"])
    extraKernelArgs = optional(list(string), ["vga=795"])
    architecture    = optional(string, "amd64")
    platform        = optional(string, "metal")
  })
  description = <<-EOT
    Base Talos image configuration used for initial node provisioning:
    - version: Talos Linux version to build (e.g., "v1.9.0").
    - extensions: (Optional) System extensions to include in the image (default: ["qemu-guest-agent"] for VM guest integration).
    - extraKernelArgs: (Optional) Additional kernel boot arguments (default: ["vga=795"] for video mode).
    - architecture: (Optional) CPU architecture for the image (default: "amd64").
    - platform: (Optional) Target platform for image optimization (default: "metal").
    EOT
}

variable "talos_image_update" {
  type = object({
    version         = optional(string, null)
    extensions      = optional(list(string), null)
    extraKernelArgs = optional(list(string), null)
    architecture    = optional(string, null)
    platform        = optional(string, null)
  })
  description = <<-EOT
    (Optional) Talos update image configuration for node upgrades. If null, no update image is generated and cluster will not be upgraded.
    - version: Talos version to upgrade to (e.g., "v1.10.0"). If null, uses base version.
    - extensions: System extensions for update image. If null, uses base extensions.
    - extraKernelArgs: Kernel arguments for update image. If null, uses base kernel arguments.
    - architecture: Architecture for update image. If null, uses base architecture.
    - platform: Platform for update image. If null, uses base platform.
    EOT
}
