variable "service_name" {
  type        = string
  description = "Hostname for the LXC container."
}

variable "environment" {
  type        = string
  description = "Environment identifier used for labels and tags."
}

variable "target_node" {
  type        = string
  description = "Proxmox node that hosts the container."
}

variable "template" {
  type        = string
  description = "VZ template name (e.g. local:vztmpl/debian-12.tar.zst)."
}

variable "cores" {
  type        = number
  description = "Number of vCPU cores."
  default     = 2
}

variable "memory_mb" {
  type        = number
  description = "RAM assigned to the container."
  default     = 2048
}

variable "swap_mb" {
  type        = number
  description = "Swap configured inside the container."
  default     = 512
}

variable "unprivileged" {
  type        = bool
  description = "Whether the container runs unprivileged."
  default     = true
}

variable "rootfs" {
  description = "Root filesystem configuration."
  type = object({
    storage = string
    size_gb = number
  })
  default = {
    storage = "lxc-data"
    size_gb = 10
  }
}

variable "network" {
  description = "Network configuration for eth0."
  type = object({
    bridge       = string
    ipv4_cidr    = string
    gateway_ipv4 = string
  })
}

variable "credentials" {
  description = "Container credentials and SSH access."
  type = object({
    password        = string
    ssh_public_keys = list(string)
  })
}

variable "tags" {
  description = "Additional tags appended to calculated labels."
  type        = list(string)
  default     = []
}

variable "extra_labels" {
  description = "Custom labels merged into the default set."
  type        = map(string)
  default     = {}
}
