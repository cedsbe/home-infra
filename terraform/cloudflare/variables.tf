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

variable "records_public_ghiot_be" {
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
  description = "A map of DNS records that can be committed to Git."
  default     = {}
}

variable "records_private_ghiot_be" {
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
  description = "A map of DNS records that must be kept private."
  default     = {}
}

variable "records_public_ghiot_net" {
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
  description = "A map of DNS records that can be committed to Git."
  default     = {}
}

variable "records_private_ghiot_net" {
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
  description = "A map of DNS records that must be kept private."
  default     = {}
}
