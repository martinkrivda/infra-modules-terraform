output "droplet_id" {
  description = "DigitalOcean droplet ID."
  value       = digitalocean_droplet.this.id
}

output "ipv4_address" {
  description = "Primary public IPv4 address of the droplet."
  value       = digitalocean_droplet.this.ipv4_address
}

output "ipv6_address" {
  description = "Primary IPv6 address (if enabled)."
  value       = digitalocean_droplet.this.ipv6_address
}
