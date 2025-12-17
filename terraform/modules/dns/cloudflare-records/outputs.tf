output "records" {
  description = "Map of managed Cloudflare records keyed by name/type/value."
  value = { for k, v in local.records_map : k => {
    id    = cloudflare_dns_record.records[k].id
    name  = cloudflare_dns_record.records[k].name
    type  = cloudflare_dns_record.records[k].type
    value = cloudflare_dns_record.records[k].value
  } }
}
