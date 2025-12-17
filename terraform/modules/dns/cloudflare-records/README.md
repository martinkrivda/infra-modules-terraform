# dns/cloudflare-records

Declares Cloudflare DNS records (single-value or sets) with sane defaults for TTL/proxying. Supports the minimalist platform pattern where Cloudflare Tunnel terminates TLS and forwards traffic to Traefik/Kubernetes services.

```hcl
module "dns" {
  source = "../../modules/dns/cloudflare-records"

  zone_id = data.cloudflare_zone.primary.id

  records = [
    {
      name    = "api"
      type    = "CNAME"
      value   = "tunnel.example.com"
      proxied = true
    },
    {
      name   = "*.apps"
      type   = "CNAME"
      value  = "tunnel.example.com"
      proxied = true
    },
    {
      name   = "git"
      type   = "AAAA"
      values = ["fd12:3456::10"]
    }
  ]
}
```
