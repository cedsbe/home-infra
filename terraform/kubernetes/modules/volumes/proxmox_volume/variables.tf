variable "volume" {
  type = object({
    name    = string
    node    = string
    size    = string
    storage = optional(string, "local-lvm")
    vmid    = optional(number, 9999)
    format  = optional(string, "raw")
  })
  description = "Volume configuration"
}
