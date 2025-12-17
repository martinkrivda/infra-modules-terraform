variable "name" {
  description = "Droplet name."
  type        = string
}

variable "region" {
  description = "DigitalOcean region slug (e.g. fra1)."
  type        = string
  default     = "fra1"
}

variable "size" {
  description = "Droplet size slug (e.g. s-2vcpu-4gb)."
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "image" {
  description = "Image slug or ID (use Debian cloud image)."
  type        = string
  default     = "debian-12-x64"
}

variable "enable_backups" {
  description = "Enable DigitalOcean snapshots/backups."
  type        = bool
  default     = false
}

variable "enable_ipv6" {
  description = "Enable IPv6 networking."
  type        = bool
  default     = true
}

variable "monitoring" {
  description = "Enable DigitalOcean monitoring agent."
  type        = bool
  default     = true
}

variable "vpc_uuid" {
  description = "Optional VPC UUID to attach the droplet to."
  type        = string
  default     = null
}

variable "ssh_keys" {
  description = "List of SSH key IDs or fingerprints."
  type        = list(string)
  default     = []
}

variable "user_data" {
  description = "Cloud-init userdata payload."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Raw tags to apply to the droplet."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Key/value labels encoded as tag strings."
  type        = map(string)
  default = {
    managed_by = "terraform"
  }
}
