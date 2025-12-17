variable "kv_engines" {
  description = "List of KV engines to enable."
  type = list(object({
    path        = string
    type        = optional(string, "kv-v2")
    description = optional(string, "")
    options     = optional(map(string), {})
  }))
  default = []
}

variable "policies" {
  description = "Map of Vault policy name -> HCL policy."
  type        = map(string)
  default     = {}
}

variable "static_secrets" {
  description = "Static KV secrets to seed (path relative to mount)."
  type = list(object({
    mount = string
    path  = string
    data  = map(string)
  }))
  default = []
}
