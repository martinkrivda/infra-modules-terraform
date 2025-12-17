terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 2.9.4"
    }
  }
}

locals {
  merged_labels = merge({
    environment = var.environment,
    component   = var.role,
    managed_by  = "terraform",
    repository  = "infra-modules-terraform",
  }, var.extra_labels)

  tags = distinct(
    compact(
      concat(
        var.tags,
        [for k, v in local.merged_labels : format("%s=%s", k, v)]
      )
    )
  )

  ipconfig0 = var.network.ipv4_cidr == null ? null : format(
    "ip=%s,gw=%s",
    var.network.ipv4_cidr,
    coalesce(var.network.gateway_ipv4, "")
  )
}

resource "proxmox_vm_qemu" "vm" {
  name                    = var.name
  target_node             = var.target_node
  desc                    = var.description
  clone                   = var.template
  full_clone              = var.full_clone
  onboot                  = true
  boot                    = var.boot_order
  bootdisk                = var.bootdisk
  scsihw                  = var.scsihw
  sockets                 = var.cpu.sockets
  cores                   = var.cpu.cores
  cpu                     = var.cpu.model
  memory                  = var.memory_mb
  agent                   = 1
  qemu_os                 = "l26"
  tags                    = join(";", local.tags)
  os_type                 = "cloud-init"
  cloudinit_cdrom_storage = var.cloudinit_storage
  kvm                     = true

  sshkeys    = join("\n", var.cloud_init.ssh_public_keys)
  ciuser     = var.cloud_init.user
  cipassword = var.cloud_init.password
  ipconfig0  = local.ipconfig0

  dynamic "disk" {
    for_each = var.disks
    content {
      type    = disk.value.type
      storage = disk.value.storage
      size    = disk.value.size_gb
      slot    = disk.value.slot
      ssd     = disk.value.ssd
      cache   = disk.value.cache
      backup  = disk.value.backup
    }
  }

  dynamic "network" {
    for_each = [var.network]
    content {
      model    = network.value.model
      bridge   = network.value.bridge
      firewall = network.value.firewall
      tag      = network.value.vlan_tag
      mtu      = network.value.mtu
    }
  }

  lifecycle {
    ignore_changes = [disk]
  }
}
