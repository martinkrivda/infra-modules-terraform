output "vm_id" {
  description = "Numeric identifier of the created VM."
  value       = proxmox_vm_qemu.vm.id
}

output "vm_name" {
  description = "Name of the VM in Proxmox."
  value       = proxmox_vm_qemu.vm.name
}

output "ip_address" {
  description = "Primary IPv4 address configured via cloud-init."
  value       = var.network.ipv4_cidr
}

output "labels" {
  description = "Label map applied to the VM for tracking."
  value       = local.merged_labels
}
