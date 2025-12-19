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
  labels = merge({
    environment = var.environment,
    component   = var.service_name,
    managed_by  = "terraform",
  }, var.extra_labels)

  tags = distinct(compact(concat(var.tags, [for k, v in local.labels : format("%s=%s", k, v)])))
}

resource "proxmox_lxc" "service" {
  target_node     = var.target_node
  hostname        = var.service_name
  ostemplate      = var.template
  password        = var.credentials.password
  ssh_public_keys = join("\n", var.credentials.ssh_public_keys)
  cores           = var.cores
  memory          = var.memory_mb
  swap            = var.swap_mb
  onboot          = true
  start           = true
  unprivileged    = var.unprivileged
  tags            = join(";", local.tags)
  features {
    nesting = true
    fuse    = true
  }
  rootfs {
    storage = var.rootfs.storage
    size    = var.rootfs.size_gb
  }
  network {
    name   = "eth0"
    bridge = var.network.bridge
    ip     = var.network.ipv4_cidr
    gw     = var.network.gateway_ipv4
  }
  lifecycle {
    ignore_changes = [rootfs]
  }
}
