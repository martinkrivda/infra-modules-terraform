variable "namespace" {
  type    = string
  default = "vault"
}

variable "chart_version" {
  type        = string
  default     = "0.28.0" # example
}

variable "values_yaml" {
  type        = string
  default     = ""
}
