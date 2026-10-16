# Resolve computed IDs during planning so reference assertions need no apply.
mock_provider "cloudflare" {
  override_during = plan

  mock_resource "cloudflare_zero_trust_tunnel_cloudflared" {
    defaults = { id = "11111111-1111-4111-8111-111111111111" }
  }
  mock_resource "cloudflare_zero_trust_tunnel_cloudflared_virtual_network" {
    defaults = { id = "22222222-2222-4222-8222-222222222222" }
  }
  mock_resource "cloudflare_zero_trust_access_policy" {
    defaults = { id = "33333333-3333-4333-8333-333333333333" }
  }
}

variables {
  account_id = "00000000000000000000000000000000"
  cloudflared_tunnels = {
    tunnel_key = { name = "test-tunnel", config_src = "cloudflare" }
  }
  virtual_networks = {
    private = { name = "private", is_default_network = true }
  }
  tunnel_routes = {
    lan = { network = "10.0.0.0/24", tunnel = "tunnel_key", virtual_network = "private" }
  }
  cloudflared_tunnel_configs = {
    ingress = {
      tunnel               = "tunnel_key"
      warp_routing_enabled = true
      origin_request       = { origin_server_name = "service.internal", connect_timeout = 15 }
      ingress = [
        { hostname = "test.example.invalid", service = "https://localhost:443", origin_request = {
          http_host_header = "service.internal"
          no_tls_verify    = false
          access           = { aud_tag = ["aud"], team_name = "team", required = true }
        } },
        { service = "http_status:404" },
      ]
    }
  }
  access_policies = {
    shared = { name = "Shared", decision = "allow", include = [{ email = { email = "test@example.invalid" } }] }
  }
  access_applications = {
    home = {
      name     = "Home"
      domain   = "test.example.invalid"
      type     = "self_hosted"
      policies = [{ policy = "shared", precedence = 1 }]
    }
  }
}

run "preserve_remote_configuration_and_policy_binding" {
  command = plan

  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.managed["ingress"].config.ingress[0].origin_request.access.required
    error_message = "Origin Access JWT validation must survive adoption."
  }
  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_config.managed["ingress"].config.origin_request.origin_server_name == "service.internal"
    error_message = "Global TLS server name must survive adoption."
  }
  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared_route.managed["lan"].tunnel_id == cloudflare_zero_trust_tunnel_cloudflared.managed["tunnel_key"].id
    error_message = "The private route must remain assigned to the correct tunnel."
  }
  assert {
    condition     = cloudflare_zero_trust_access_application.managed["home"].policies[0].id == cloudflare_zero_trust_access_policy.managed["shared"].id
    error_message = "Reusable policies must attach through the Access application."
  }
  assert {
    condition     = length(data.cloudflare_zero_trust_tunnel_cloudflared_token.managed) == 0
    error_message = "Adoption must not read deployment tokens by default."
  }
}

run "reject_lost_private_routes" {
  command = plan
  variables {
    tunnel_routes = {}
  }
  expect_failures = [cloudflare_zero_trust_tunnel_cloudflared_config.managed["ingress"]]
}
