output "zone_ids" {
  description = "Zone IDs read from managed resources."
  value       = { for key, zone in cloudflare_zone.managed : key => zone.id }
}
output "record_ids" {
  description = "DNS record IDs keyed by the input map keys."
  value       = { for key, record in cloudflare_dns_record.managed : key => record.id }
}
