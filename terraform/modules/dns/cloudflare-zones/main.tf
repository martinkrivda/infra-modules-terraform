resource "cloudflare_zone" "managed" {
  for_each = var.zones

  account             = { id = var.account_id }
  name                = each.key
  paused              = try(each.value.paused, null)
  type                = try(each.value.type, "full")
  vanity_name_servers = try(each.value.vanity_name_servers, null)
  lifecycle {
    prevent_destroy = true
  }

}

resource "cloudflare_dns_record" "managed" {
  for_each = var.dns_records

  name     = try(each.value.name, null)
  ttl      = try(each.value.ttl, 1)
  type     = try(each.value.type, null)
  zone_id  = cloudflare_zone.managed[each.value.zone].id
  comment  = try(each.value.comment, null)
  content  = try(each.value.content, null)
  data     = try(each.value.data, null)
  priority = try(each.value.priority, null)
  proxied  = try(each.value.proxied, false)
  settings = try(each.value.settings, null)
  tags     = try(each.value.tags, null)
}

