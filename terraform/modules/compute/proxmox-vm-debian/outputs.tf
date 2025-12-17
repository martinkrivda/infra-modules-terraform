output "name" {
  value = proxmox_vm_qemu.this.name
}

output "ipv4" {
  value = var.ip_address
}

output "vmid" {
  value = proxmox_vm_qemu.this.vmid
}