variable "name" {
  type        = string
  description = "Name of the Proxmox VM and hostname reported by cloud-init."
}

variable "description" {
  type        = string
  description = "Optional VM description shown in the Proxmox UI."
  default     = "Managed by Terraform"
}

variable "environment" {
  type        = string
  description = "Environment label (e.g. lab, staging, production)."
}

variable "role" {
  type        = string
  description = "Functional role (k3s-server, k3s-worker, registry, etc.)."
  default     = "k3s"
}

variable "target_node" {
  type        = string
  description = "Name of the Proxmox node where the VM will run."
}

variable "template" {
  type        = string
  description = "Existing Proxmox template to clone (cloud-init ready)."
}

variable "full_clone" {
  type        = bool
  description = "Clone template as a full clone (otherwise linked clone)."
  default     = true
}

variable "tags" {
  type        = list(string)
  description = "Additional Proxmox tags that will be appended to computed labels."
  default     = []
}

variable "extra_labels" {
  type        = map(string)
  description = "Supplemental metadata merged into the default label map."
  default     = {}
}

variable "cpu" {
  description = "CPU settings for the VM."
  type = object({
    sockets = number
    cores   = number
    model   = string
  })
  default = {
    sockets = 1
    cores   = 2
    model   = "host"
  }
}

variable "memory_mb" {
  type        = number
  description = "Memory assigned to the VM (in MB)."
  default     = 4096
}

variable "cloudinit_storage" {
  type        = string
  description = "Datastore that holds the cloud-init ISO (usually same as template storage)."
  default     = "local-lvm"
}

variable "boot_order" {
  type        = string
  description = "Boot order string passed to Proxmox (e.g. order=scsi0;ide2;net0)."
  default     = "order=scsi0"
}

variable "bootdisk" {
  type        = string
  description = "Disk to boot from (scsi0, sata0, etc.)."
  default     = "scsi0"
}

variable "scsihw" {
  type        = string
  description = "Controller type for scsi disks."
  default     = "virtio-scsi-single"
}

variable "cloud_init" {
  description = "Cloud-init settings for user + SSH access."
  type = object({
    user            = string
    password        = string
    ssh_public_keys = list(string)
  })
  default = {
    user            = "debian"
    password        = "changeMe123!"
    ssh_public_keys = []
  }
}

variable "disks" {
  description = "Disk definitions. slot refers to the disk device number (e.g. 0 for scsi0)."
  type = list(object({
    type    = string
    storage = string
    size_gb = number
    slot    = number
    ssd     = optional(bool, true)
    cache   = optional(string, "writeback")
    backup  = optional(bool, true)
  }))
  default = [
    {
      type    = "scsi"
      storage = "local-lvm"
      size_gb = 40
      slot    = 0
    }
  ]
}

variable "network" {
  description = "Primary network interface config."
  type = object({
    bridge       = string
    model        = optional(string, "virtio")
    firewall     = optional(bool, true)
    vlan_tag     = optional(number)
    mtu          = optional(number, 1500)
    ipv4_cidr    = optional(string)
    gateway_ipv4 = optional(string)
  })
  default = {
    bridge    = "vmbr0"
    ipv4_cidr = null
  }
}
