variable "name"        { type = string }
variable "vmid"        { type = number }
variable "target_node" { type = string }

variable "template_name" { type = string }  # např. "debian-13-cloudinit"

variable "cores"     { type = number }
variable "memory_mb" { type = number }
variable "disk_gb"   { type = number }

variable "bridge"  { type = string }
variable "storage" { type = string }

variable "ip_address" { type = string }  # "192.168.10.10/24"
variable "gateway"    { type = string }  # "192.168.10.1"

variable "ci_user" {
  type        = string
  default     = "debian"
  description = "cloud-init user (Debian default user)"
}

variable "ssh_public_key" {
  type        = string
  sensitive   = true
}
