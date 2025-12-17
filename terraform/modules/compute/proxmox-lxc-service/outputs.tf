output "hostname" {
  description = "Hostname of the LXC service."
  value       = proxmox_lxc.service.hostname
}

output "labels" {
  description = "Label map applied to metadata."
  value       = local.labels
}
