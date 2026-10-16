variable "account_id" {
  description = "Cloudflare account owning the zones."
  type        = string

}

variable "zones" {
  description = "Zones keyed by domain; zone_id records the existing ID for import and is checked against state."
  type        = any
  default     = {}
}

variable "dns_records" {
  description = "DNS records keyed by a stable label or existing ID; zone selects a zones map key. Supports content or data, settings and tags."
  type        = any
  default     = {}
}

