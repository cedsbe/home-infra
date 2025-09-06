# -----------------------------------------------------------------------------
# DNS Records Configuration
# -----------------------------------------------------------------------------

# Public DNS records (safe to commit to Git)
resource "cloudflare_dns_record" "public" {
  for_each = var.records_public

  zone_id  = var.zone_ids[each.value.zone_name]
  name     = each.value.name
  ttl      = each.value.ttl
  type     = each.value.type
  content  = each.value.content
  proxied  = each.value.proxied
  priority = each.value.priority
  comment  = each.value.comment
}

# Private DNS records (kept in secrets file)
resource "cloudflare_dns_record" "private" {
  for_each = var.records_private

  zone_id  = var.zone_ids[each.value.zone_name]
  name     = each.value.name
  ttl      = each.value.ttl
  type     = each.value.type
  content  = each.value.content
  proxied  = each.value.proxied
  priority = each.value.priority
  comment  = each.value.comment
}
