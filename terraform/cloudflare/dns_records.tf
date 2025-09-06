# -----------------------------------------------------------------------------
# Resources to configure the ghiot.be DNS zone
# -----------------------------------------------------------------------------

resource "cloudflare_dns_record" "records_public_ghiot_be" {
  for_each = var.records_public_ghiot_be

  zone_id  = var.zone_ids[each.value.zone_name]
  name     = each.value.name
  ttl      = each.value.ttl
  type     = each.value.type
  content  = each.value.content
  proxied  = each.value.proxied
  priority = each.value.priority
  comment  = each.value.comment
}

resource "cloudflare_dns_record" "records_private_ghiot_be" {
  for_each = var.records_private_ghiot_be

  zone_id  = var.zone_ids[each.value.zone_name]
  name     = each.value.name
  ttl      = each.value.ttl
  type     = each.value.type
  content  = each.value.content
  proxied  = each.value.proxied
  priority = each.value.priority
  comment  = each.value.comment
}

# -----------------------------------------------------------------------------
# Resources to configure the ghiot.net DNS zone
# -----------------------------------------------------------------------------

resource "cloudflare_dns_record" "records_public_ghiot_net" {
  for_each = var.records_public_ghiot_net

  zone_id  = var.zone_ids[each.value.zone_name]
  name     = each.value.name
  ttl      = each.value.ttl
  type     = each.value.type
  content  = each.value.content
  proxied  = each.value.proxied
  priority = each.value.priority
  comment  = each.value.comment
}

resource "cloudflare_dns_record" "records_private_ghiot_net" {
  for_each = var.records_private_ghiot_net

  zone_id  = var.zone_ids[each.value.zone_name]
  name     = each.value.name
  ttl      = each.value.ttl
  type     = each.value.type
  content  = each.value.content
  proxied  = each.value.proxied
  priority = each.value.priority
  comment  = each.value.comment
}
