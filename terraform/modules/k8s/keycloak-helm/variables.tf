variable "release_name" {
  type        = string
  description = "Helm release name for Keycloak."
  default     = "keycloak"
}

variable "namespace" {
  type        = string
  description = "Namespace for the release."
  default     = "keycloak"
}

variable "repository" {
  type        = string
  description = "Helm repository URL."
  default     = "https://charts.bitnami.com/bitnami"
}

variable "chart" {
  type        = string
  description = "Helm chart name."
  default     = "keycloak"
}

variable "chart_version" {
  type        = string
  description = "Helm chart version."
  default     = "21.3.1"
}

variable "replicas" {
  type        = number
  description = "Number of Keycloak replicas."
  default     = 1
}

variable "external_database" {
  description = "Connection settings for the external PostgreSQL database."
  type = object({
    host                 = string
    port                 = number
    database             = string
    user                 = string
    password_secret_name = string
    password_secret_key  = string
  })
}

variable "admin" {
  description = "Admin credential secret metadata."
  type = object({
    user        = string
    secret_name = string
    secret_key  = string
  })
}

variable "ingress" {
  description = "Ingress configuration for exposing Keycloak."
  type = object({
    enabled         = bool
    hostname        = string
    tls_secret_name = string
    annotations     = map(string)
  })
  default = {
    enabled         = true
    hostname        = "sso.example.com"
    tls_secret_name = "keycloak-tls"
    annotations     = {}
  }
}

variable "extra_env" {
  description = "Additional env vars injected into the pods."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "extra_values" {
  description = "Fully custom Helm values merged on top of defaults."
  type        = map(any)
  default     = {}
}
