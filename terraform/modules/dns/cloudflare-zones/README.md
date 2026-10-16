# Cloudflare zone and DNS adoption

Manage imported zones and DNS records with stable map keys. Credentials stay in
the consuming root provider. Requires Terraform >= 1.7 and Cloudflare = 5.14.0,
matching the consumer and adoption inventory schema. The mocked tests require
Terraform >= 1.11: they resolve mock IDs during `plan` and never apply or destroy
protected zones.

```hcl
module "cloudflare_dns" {
  source     = "../../modules/dns/cloudflare-zones"
  account_id = var.account_id
  zones = {
    "example.invalid" = { type = "full", paused = false }
  }
  dns_records = {
    record_key = {
      zone    = "example.invalid"
      name    = "www.example.invalid"
      type    = "CNAME"
      content = "service.example.invalid"
      ttl     = 1
      proxied = true
    }
  }
}
```

Each record accepts provider attributes `name`, `type`, `ttl`, `content` OR `data`,
`proxied`, `priority`, `comment`, `settings`, and `tags`, plus `zone` selecting a
zone key. Zones accept `type`, `paused`, and `vanity_name_servers`.
Optional `zone_id` is import metadata; records reference the managed resource ID.
The module adds no comments, tags, or proxy changes during adoption.

Import addresses are `module.cloudflare_dns.cloudflare_zone.managed["example.invalid"]`
and `module.cloudflare_dns.cloudflare_dns_record.managed["record_key"]`.
Import IDs are `<zone_id>` and `<zone_id>/<record_id>` respectively.
Zones have `prevent_destroy`; records remain individually manageable.

Nested maps use `any` to preserve heterogeneous provider objects without Terraform
silently discarding fields during narrow object conversions. The provider validates
their schemas. Consumers should use a schema-checked inventory and require a no-op
plan before any apply. Unspecified maps default to empty, so no zone is implicit.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| account_id | Account owning the zones | string | n/a | yes |
| zones | Zones keyed by domain | any | {} | no |
| dns_records | Records keyed by stable label or ID | any | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| zone_ids | Actual managed zone IDs |
| record_ids | DNS record IDs keyed by input keys |
<!-- END_TF_DOCS -->
