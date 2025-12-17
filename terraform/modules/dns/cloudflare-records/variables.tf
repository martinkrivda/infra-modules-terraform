variable "zone_id" {
  type        = string
  description = "Cloudflare zone identifier where records will be managed."
}

variable "records" {
  description = "List of records to manage. Use values for multi-value records."
  type = list(object({
    name     = string
    type     = string
    value    = optional(string)
    values   = optional(list(string), [])
    ttl      = optional(number)
    proxied  = optional(bool)
    priority = optional(number)
    comment  = optional(string)
  }))
  default = []
}

variable "default_ttl" {
  type        = number
  description = "TTL applied when none is provided for a record."
  default     = 300
}

variable "default_proxied" {
  type        = bool
  description = "Whether records are proxied when not explicitly set."
  default     = false
}
