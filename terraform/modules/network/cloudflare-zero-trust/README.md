# Cloudflare Zero Trust adoption

Manage remotely configured cloudflared tunnels, full origin settings, private CIDR
routes, virtual networks and Access applications/policies. The root supplies the
Cloudflare provider and account ID. Requires Terraform >= 1.7, Cloudflare >= 5.14,
< 6. Pin an exact provider in consumers; the adoption example uses 5.14.0.

All maps default to empty. Keys are stable labels or existing UUIDs; `name` is an
independent attribute so renaming an object does not change its Terraform address.
The module supports all writable Access application and reusable policy attributes
from provider 5.14. `any` inputs preserve heterogeneous provider objects rather than
silently narrowing them; the provider validates nested schemas.

- `cloudflared_tunnels`: `name`, `config_src` (default `cloudflare`). Locally managed
  metadata can be imported, but local YAML and tunnel secrets are not managed.
- `cloudflared_tunnel_configs`: `tunnel` key, `ingress` list, global `origin_request`,
  and explicit `warp_routing_enabled`. Each ingress entry accepts `origin_request`.
  Cloudflare provider 5.14 removed the old WARP switch: routes enable private
  routing. A precondition verifies the exported enabled state against route
  assignments to catch lost routes. Do not attach remote config to a local tunnel.
- `tunnel_routes`: `network` CIDR, `tunnel` key, optional `virtual_network` key and
  `comment`.
- `virtual_networks`: `name`, optional `comment` and `is_default_network`.
- `access_policies`: reusable account policies, including full include/exclude/
  require rules, approval settings, session duration and isolation settings.
- `access_applications`: provider attributes. `policies` entries either reference
  `{ policy = "shared-key", precedence = 1 }` or contain a full application-exclusive
  policy with its existing ID and precedence. Policies attach through the
  application. Legacy `application` and `precedence` on an account policy also
  attach it to a named application; use a unique explicit precedence per app.
  Account scope is the default; supplying `zone_id` selects legacy zone scope.

```hcl
access_policies = {
  shared = {
    name     = "Staff"
    decision = "allow"
    include  = [{ email_domain = { domain = "example.invalid" } }]
  }
}
access_applications = {
  home = {
    name     = "Home"
    type     = "self_hosted"
    domain   = "home.example.invalid"
    policies = [{ policy = "shared", precedence = 1 }]
  }
}
```

`read_tunnel_tokens` defaults to false. Enabling it reads the separate
`cloudflare_zero_trust_tunnel_cloudflared_token` data source for remote tunnels.
The output is sensitive, but tokens also reside in Terraform state.

Import addresses follow `module.cloudflare_zero_trust.<resource>.managed["key"]`.
Tunnel/config IDs are `<account_id>/<tunnel_id>`; route, virtual network and reusable
policy IDs are `<account_id>/<resource_id>`. Application IDs are
`accounts/<account_id>/<app_id>` or `zones/<zone_id>/<app_id>`. App-exclusive policies
remain embedded in the imported application. Tunnels and virtual networks have
`prevent_destroy`. Reconcile a no-op plan before any apply.

This module covers these resources only. IdPs, Access groups, service-token
creation, Gateway, device profiles and local cloudflared YAML need separate owners.
Existing IDs in policy rules are preserved as external references.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| account_id | Zero Trust account ID | string | n/a | yes |
| cloudflared_tunnels | Tunnel metadata | any | {} | no |
| cloudflared_tunnel_configs | Full remote ingress and origin configuration | any | {} | no |
| tunnel_routes | Private CIDR route assignments | any | {} | no |
| virtual_networks | Virtual networks | any | {} | no |
| access_applications | Applications and ordered policy bindings | any | {} | no |
| access_policies | Reusable account policies | any | {} | no |
| read_tunnel_tokens | Read deployment secrets into state | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| tunnel_ids | Tunnel IDs by input key |
| application_ids | Application IDs by input key |
| tunnel_tokens | Opt-in sensitive deployment tokens |
<!-- END_TF_DOCS -->
