output "tunnel_ids" {
  description = "Tunnel IDs keyed by stable input keys."
  value       = { for key, tunnel in cloudflare_zero_trust_tunnel_cloudflared.managed : key => tunnel.id }
}
output "application_ids" {
  description = "Access application IDs keyed by stable input keys."
  value       = { for key, app in cloudflare_zero_trust_access_application.managed : key => app.id }
}
output "tunnel_tokens" {
  description = "Opt-in deployment tokens; these secrets also reside in Terraform state."
  value       = { for key, token in data.cloudflare_zero_trust_tunnel_cloudflared_token.managed : key => token.token }
  sensitive   = true
}
