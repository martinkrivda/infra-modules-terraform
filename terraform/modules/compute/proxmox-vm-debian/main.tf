terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 3.0.2-rc07"
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
        [
          for k, v in local.merged_labels : trim(
            replace(
              replace(format("%s-%s", k, v), "=", "-"),
              " ",
              "-"
            ),
            "-."
          )
        ]
      )
    )
  )

  clone_source = var.template_vmid != null ? tostring(var.template_vmid) : var.template

  cpu = {
    sockets = coalesce(var.cpu_sockets, var.cpu.sockets)
    cores   = coalesce(var.cpu_cores, var.cpu.cores)
    model   = var.cpu.model
  }

  memory_mb = coalesce(var.memory_override_mb, var.memory_mb)

  effective_ipv4_cidr = var.ipv4_address != null ? format(
    "%s/%s",
    var.ipv4_address,
    coalesce(var.ipv4_prefix_length, 32)
  ) : var.network.ipv4_cidr

  effective_gateway = var.ipv4_gateway != null ? var.ipv4_gateway : var.network.gateway_ipv4

  ipconfig0 = local.effective_ipv4_cidr == null ? null : format(
    "ip=%s,gw=%s",
    local.effective_ipv4_cidr,
    coalesce(local.effective_gateway, "")
  )

  ssh_public_keys = var.ssh_public_keys != null ? var.ssh_public_keys : var.cloud_init.ssh_public_keys

  disk_defaults = {
    type   = "scsi"
    ssd    = true
    cache  = "writeback"
    backup = true
  }

  os_disk_override = var.os_disk == null ? [] : [merge(
    local.disk_defaults,
    {
      type    = coalesce(try(var.os_disk.type, null), "scsi")
      storage = var.os_disk.storage
      size_gb = var.os_disk.size_gb
      slot    = coalesce(try(var.os_disk.slot, null), 0)
      ssd     = coalesce(try(var.os_disk.ssd, null), true)
      cache   = coalesce(try(var.os_disk.cache, null), "writeback")
      backup  = coalesce(try(var.os_disk.backup, null), true)
    }
  )]

  base_disks = length(local.os_disk_override) > 0 ? local.os_disk_override : var.disks

  base_disk_slots = [for disk in local.base_disks : disk.slot]
  next_disk_slot  = length(local.base_disk_slots) == 0 ? 0 : max(local.base_disk_slots...) + 1

  data_disk_overrides = [
    for idx, disk in var.data_disks : merge(
      local.disk_defaults,
      {
        type    = coalesce(try(disk.type, null), "scsi")
        storage = disk.storage
        size_gb = disk.size_gb
        slot    = coalesce(try(disk.slot, null), local.next_disk_slot + idx)
        ssd     = coalesce(try(disk.ssd, null), true)
        cache   = coalesce(try(disk.cache, null), "writeback")
        backup  = coalesce(try(disk.backup, null), true)
      }
    )
  ]

  disks = length(var.data_disks) > 0 ? concat(
    local.base_disks,
    local.data_disk_overrides,
  ) : local.base_disks
}

resource "proxmox_vm_qemu" "vm" {
  name               = var.name
  target_node        = var.target_node
  description        = var.description
  clone              = local.clone_source
  full_clone         = var.full_clone
  start_at_node_boot = true
  boot               = var.boot_order
  bootdisk           = var.bootdisk
  scsihw             = var.scsihw
  cpu {
    cores   = local.cpu.cores
    sockets = local.cpu.sockets
    type    = local.cpu.model
  }
  memory  = local.memory_mb
  agent   = 1
  qemu_os = "l26"
  tags    = join(";", local.tags)
  os_type = "cloud-init"
  disk {
    type    = "cloudinit"
    storage = var.cloudinit_storage
    slot    = var.cloudinit_disk_slot
  }
  kvm  = true
  pool = var.pool

  sshkeys    = join("\n", local.ssh_public_keys)
  ciuser     = var.cloud_init.user
  cipassword = var.cloud_init.password
  ipconfig0  = local.ipconfig0
  cicustom   = var.cicustom

  dynamic "disk" {
    for_each = local.disks
    content {
      type    = "disk"
      storage = disk.value.storage
      size    = disk.value.size_gb
      slot    = format("%s%s", disk.value.type, disk.value.slot)
      cache   = disk.value.cache
      backup  = disk.value.backup
    }
  }

  dynamic "network" {
    for_each = [var.network]
    content {
      id       = 0
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
