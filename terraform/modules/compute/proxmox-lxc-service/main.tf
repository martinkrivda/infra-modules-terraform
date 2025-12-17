resource "proxmox_lxc" "this" {
  hostname    = var.hostname
  vmid        = var.vmid
  target_node = var.target_node

  ostemplate = var.ostemplate         # např. "iso-store:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"

  cores  = var.cores
  memory = var.memory_mb

  rootfs {
    storage = var.rootfs_storage
    size    = "${var.rootfs_size_gb}G"
  }

  net0 = "name=eth0,bridge=${var.bridge},ip=${var.ip_cidr},gw=${var.gateway}"

  password = var.root_password

  features {
    nesting = var.nesting
  }

  onboot = true
}