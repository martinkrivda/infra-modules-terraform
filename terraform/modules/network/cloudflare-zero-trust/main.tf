resource "cloudflare_zero_trust_tunnel_cloudflared" "managed" {
  for_each = var.cloudflared_tunnels

  account_id = var.account_id
  name       = try(each.value.name, each.key)
  config_src = try(each.value.config_src, "cloudflare")
  lifecycle {
    prevent_destroy = true
  }

}

resource "cloudflare_zero_trust_tunnel_cloudflared_virtual_network" "managed" {
  for_each = var.virtual_networks

  account_id         = var.account_id
  name               = try(each.value.name, each.key)
  comment            = try(each.value.comment, null)
  is_default_network = try(each.value.is_default_network, null)
  lifecycle {
    prevent_destroy = true
  }

}

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "managed" {
  for_each = var.tunnel_routes

  account_id         = var.account_id
  network            = try(each.value.network, null)
  tunnel_id          = cloudflare_zero_trust_tunnel_cloudflared.managed[each.value.tunnel].id
  comment            = try(each.value.comment, null)
  virtual_network_id = try(each.value.virtual_network, null) == null ? null : cloudflare_zero_trust_tunnel_cloudflared_virtual_network.managed[each.value.virtual_network].id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "managed" {
  for_each   = var.cloudflared_tunnel_configs
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.managed[each.value.tunnel].id
  source     = "cloudflare"
  config = {
    ingress        = try(each.value.ingress, [])
    origin_request = try(each.value.origin_request, null)
  }
  lifecycle {
    precondition {
      condition     = try(var.cloudflared_tunnels[each.value.tunnel].config_src, "cloudflare") == "cloudflare"
      error_message = "Remote configuration cannot manage a locally configured tunnel."
    }
    precondition {
      condition     = each.value.warp_routing_enabled == anytrue([for route in var.tunnel_routes : route.tunnel == each.value.tunnel])
      error_message = "Provider 5.14 derives WARP routing from private routes. Preserve the inventory route assignments."
    }
  }
}

resource "cloudflare_zero_trust_access_policy" "managed" {
  for_each = var.access_policies

  account_id                     = var.account_id
  decision                       = try(each.value.decision, "allow")
  name                           = try(each.value.name, each.key)
  approval_groups                = try(each.value.approval_groups, null)
  approval_required              = try(each.value.approval_required, null)
  exclude                        = try(each.value.exclude, null)
  include                        = try(each.value.include, null)
  isolation_required             = try(each.value.isolation_required, null)
  purpose_justification_prompt   = try(each.value.purpose_justification_prompt, null)
  purpose_justification_required = try(each.value.purpose_justification_required, null)
  require                        = try(each.value.require, null)
  session_duration               = try(each.value.session_duration, null)
}

resource "cloudflare_zero_trust_access_application" "managed" {
  for_each = var.access_applications

  account_id                   = try(each.value.zone_id, null) == null ? var.account_id : null
  allow_authenticate_via_warp  = try(each.value.allow_authenticate_via_warp, null)
  allow_iframe                 = try(each.value.allow_iframe, null)
  allowed_idps                 = try(each.value.allowed_idps, null)
  app_launcher_logo_url        = try(each.value.app_launcher_logo_url, null)
  app_launcher_visible         = try(each.value.app_launcher_visible, null)
  auto_redirect_to_identity    = try(each.value.auto_redirect_to_identity, null)
  bg_color                     = try(each.value.bg_color, null)
  cors_headers                 = try(each.value.cors_headers, null)
  custom_deny_message          = try(each.value.custom_deny_message, null)
  custom_deny_url              = try(each.value.custom_deny_url, null)
  custom_non_identity_deny_url = try(each.value.custom_non_identity_deny_url, null)
  custom_pages                 = try(each.value.custom_pages, null)
  destinations                 = try(each.value.destinations, null)
  domain                       = try(each.value.domain, null)
  enable_binding_cookie        = try(each.value.enable_binding_cookie, null)
  footer_links                 = try(each.value.footer_links, null)
  header_bg_color              = try(each.value.header_bg_color, null)
  http_only_cookie_attribute   = try(each.value.http_only_cookie_attribute, null)
  landing_page_design          = try(each.value.landing_page_design, null)
  logo_url                     = try(each.value.logo_url, null)
  name                         = try(each.value.name, each.key)
  options_preflight_bypass     = try(each.value.options_preflight_bypass, null)
  path_cookie_attribute        = try(each.value.path_cookie_attribute, null)
  policies = [for policy in concat(
    try(each.value.policies, []),
    [for key, policy in var.access_policies : { policy = key, precedence = try(policy.precedence, null) } if try(policy.application, null) == each.key]
    ) : merge(
    { for key, value in policy : key => value if key != "policy" },
    try(policy.policy, null) == null ? {} : { id = cloudflare_zero_trust_access_policy.managed[policy.policy].id }
  )]
  read_service_tokens_from_header = try(each.value.read_service_tokens_from_header, null)
  saas_app                        = try(each.value.saas_app, null)
  same_site_cookie_attribute      = try(each.value.same_site_cookie_attribute, null)
  scim_config                     = try(each.value.scim_config, null)
  self_hosted_domains             = try(each.value.self_hosted_domains, null)
  service_auth_401_redirect       = try(each.value.service_auth_401_redirect, null)
  session_duration                = try(each.value.session_duration, null)
  skip_app_launcher_login_page    = try(each.value.skip_app_launcher_login_page, null)
  skip_interstitial               = try(each.value.skip_interstitial, null)
  tags                            = try(each.value.tags, null)
  target_criteria                 = try(each.value.target_criteria, null)
  type                            = try(each.value.type, null)
  zone_id                         = try(each.value.zone_id, null)
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "managed" {
  for_each   = { for key, tunnel in var.cloudflared_tunnels : key => tunnel if var.read_tunnel_tokens && try(tunnel.config_src, "cloudflare") == "cloudflare" }
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.managed[each.key].id
}
