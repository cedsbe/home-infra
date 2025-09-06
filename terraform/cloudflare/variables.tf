variable "zone_ids" {
  description = "Map of domain names to their Cloudflare zone IDs"
  type        = map(string)
  sensitive   = true

  validation {
    condition = alltrue([
      for zone_id in values(var.zone_ids) : can(regex("^[a-f0-9]{32}$", zone_id))
    ])
    error_message = "Zone IDs must be 32-character hexadecimal strings."
  }
}

variable "records_public" {
  type = map(object({
    zone_name = string
    name      = string
    ttl       = optional(number, 60)
    type      = string
    comment   = string
    content   = string
    proxied   = optional(bool, false)
    priority  = optional(number, null)
  }))
  description = "A map of DNS records that can be committed to Git. Supports all zones configured in zone_ids."
  default     = {}
}

variable "records_private" {
  type = map(object({
    zone_name = string
    name      = string
    ttl       = optional(number, 60)
    type      = string
    comment   = string
    content   = string
    proxied   = optional(bool, false)
    priority  = optional(number, null)
  }))
  description = "A map of DNS records that must be kept private. Supports all zones configured in zone_ids."
  default     = {}
}
