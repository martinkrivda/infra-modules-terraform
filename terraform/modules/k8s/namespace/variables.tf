variable "name" {
  description = "Namespace name."
  type        = string
}

variable "environment" {
  description = "Environment label added to namespace metadata."
  type        = string
}

variable "component" {
  description = "Logical component/workload label."
  type        = string
  default     = "app"
}

variable "labels" {
  description = "Extra labels applied to the namespace."
  type        = map(string)
  default     = {}
}

variable "annotations" {
  description = "Namespace annotations."
  type        = map(string)
  default     = {}
}

variable "resource_quota" {
  description = "Optional resource quota map (keys align with Kubernetes resource names)."
  type        = map(string)
  default     = null
}

variable "limit_range" {
  description = "Optional limit range definition."
  type = object({
    default_cpu    = string
    default_memory = string
    request_cpu    = string
    request_memory = string
  })
  default = null
}
