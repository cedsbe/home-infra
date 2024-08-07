variable "talos_image_base" {
  type = object({
    version         = string
    extensions      = optional(list(string), ["qemu-guest-agent"])
    extraKernelArgs = optional(list(string), ["vga=795"])
    architecture    = optional(string, "amd64")
    platform        = optional(string, "metal")
  })
  description = "Base Talos image configuration."
  default = {
    version = "v1.9.0"
  }
}

variable "talos_image_update" {
  type = object({
    version         = optional(string, null)
    extensions      = optional(list(string), null)
    extraKernelArgs = optional(list(string), null)
    architecture    = optional(string, null)
    platform        = optional(string, null)
  })
  description = "(Optional) Set when Updating. Talos update image configuration. Default to null."
  default     = null
}
