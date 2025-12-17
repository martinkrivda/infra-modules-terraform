terraform {
  required_version = ">= 1.5.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.28.0"
    }
  }
}

locals {
  flattened_records = flatten([
    for record in var.records : [
      for value in(length(record.values) > 0 ? record.values : [record.value]) : {
        key      = format("%s|%s|%s", record.name, record.type, value)
        name     = record.name
        type     = record.type
        content  = value
        ttl      = coalesce(record.ttl, var.default_ttl)
        proxied  = coalesce(record.proxied, var.default_proxied)
        priority = record.priority
        comment  = coalesce(record.comment, "managed by terraform")
      }
    ]
  ])

  records_map = { for item in local.flattened_records : item.key => item }
}

resource "cloudflare_dns_record" "records" {
  for_each = local.records_map

  zone_id  = var.zone_id
  name     = each.value.name
  type     = each.value.type
  content  = each.value.content
  ttl      = each.value.ttl
  proxied  = each.value.proxied
  priority = each.value.priority
  comment  = each.value.comment
}
