resource "cloudflare_record" "this" {
  zone_id = var.zone_id
  name    = var.name
  type    = var.type
  value   = var.value
  proxied = var.proxied
  ttl     = var.ttl
}
