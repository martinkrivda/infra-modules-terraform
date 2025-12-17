resource "proxmox_vm_qemu" "this" {
  name        = var.name
  vmid        = var.vmid
  target_node = var.target_node

  clone      = var.template_name
  full_clone = true
  os_type    = "cloud-init"

  cores   = var.cores
  sockets = 1
  memory  = var.memory_mb

  scsihw = "virtio-scsi-pci"

  disk {
    size    = "${var.disk_gb}G"
    type    = "scsi"
    storage = var.storage
    discard = "on"
  }

  network {
    model  = "virtio"
    bridge = var.bridge
  }

  # cloud-init
  ciuser    = var.ci_user
  sshkeys   = var.ssh_public_key
  ipconfig0 = "ip=${var.ip_address},gw=${var.gateway}"

  onboot = true
}
