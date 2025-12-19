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

variable "pool" {
  type        = string
  description = "Optional Proxmox resource pool that should contain the VM."
  default     = null
}

variable "template" {
  type        = string
  description = "Existing Proxmox template to clone (cloud-init ready)."
}

variable "template_vmid" {
  type        = number
  description = "Numeric VMID of the template to clone instead of referencing by name."
  default     = null
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

variable "cloudinit_disk_slot" {
  type        = string
  description = "Slot identifier reserved for the cloud-init drive (e.g. ide2)."
  default     = "ide2"
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

variable "ssh_public_keys" {
  description = "Optional override for SSH public keys injected via cloud-init."
  type        = list(string)
  default     = null
}

variable "cpu_cores" {
  description = "Optional override for number of cores per socket."
  type        = number
  default     = null
}

variable "cpu_sockets" {
  description = "Optional override for number of CPU sockets."
  type        = number
  default     = null
}

variable "memory_override_mb" {
  description = "Optional override for memory in MB (falls back to memory_mb when unset)."
  type        = number
  default     = null
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

variable "os_disk" {
  description = "Optional simplified definition for the OS disk; overrides the first entry in disks."
  type = object({
    size_gb = number
    storage = string
    type    = optional(string, "scsi")
    slot    = optional(number)
    ssd     = optional(bool, true)
    cache   = optional(string, "writeback")
    backup  = optional(bool, true)
  })
  default  = null
  nullable = true
}

variable "data_disks" {
  description = "Optional list of simplified data disks appended after the OS disk."
  type = list(object({
    size_gb = number
    storage = string
    type    = optional(string, "scsi")
    slot    = optional(number)
    ssd     = optional(bool, true)
    cache   = optional(string, "writeback")
    backup  = optional(bool, true)
  }))
  default = []
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

variable "ipv4_address" {
  description = "Optional plain IPv4 address that will be combined with ipv4_prefix_length."
  type        = string
  default     = null
}

variable "ipv4_prefix_length" {
  description = "Optional prefix length for ipv4_address (defaults to /32 when omitted)."
  type        = number
  default     = null
}

variable "ipv4_gateway" {
  description = "Optional IPv4 gateway override when ipv4_address is specified."
  type        = string
  default     = null
}
