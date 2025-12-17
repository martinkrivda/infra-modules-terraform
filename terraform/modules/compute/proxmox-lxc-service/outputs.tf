output "hostname" {
  value = proxmox_lxc.this.hostname
}

output "ipv4" {
  value = var.ip_cidr
}
