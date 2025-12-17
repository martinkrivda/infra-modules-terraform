variable "hostname"    { type = string }
variable "vmid"        { type = number }
variable "target_node" { type = string }

variable "ostemplate" {
  type        = string
  description = "LXC OS template (e.g. iso-store:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst)"
}

variable "cores"       { type = number }
variable "memory_mb"   { type = number }
variable "rootfs_storage" { type = string }
variable "rootfs_size_gb" { type = number }

variable "bridge"  { type = string }
variable "ip_cidr" { type = string }
variable "gateway" { type = string }

variable "root_password" {
  type        = string
  sensitive   = true
}

variable "nesting" {
  type    = bool
  default = false
}
