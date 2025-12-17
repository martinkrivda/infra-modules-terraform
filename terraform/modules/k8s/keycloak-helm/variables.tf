variable "namespace" {
  type    = string
  default = "keycloak"
}

variable "chart_version" {
  type        = string
  default     = "22.2.0" # příklad
}

variable "values_yaml" {
  type        = string
  default     = ""
}
