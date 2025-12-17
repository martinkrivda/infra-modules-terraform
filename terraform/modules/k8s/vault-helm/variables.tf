variable "release_name" {
  type        = string
  description = "Helm release name."
  default     = "vault"
}

variable "namespace" {
  type        = string
  description = "Namespace where Vault will run."
  default     = "vault"
}

variable "repository" {
  type        = string
  description = "Helm repo URL."
  default     = "https://helm.releases.hashicorp.com"
}

variable "chart" {
  type        = string
  description = "Chart name."
  default     = "vault"
}

variable "chart_version" {
  type        = string
  description = "Chart version."
  default     = "0.27.0"
}

variable "ha_enabled" {
  type        = bool
  description = "Whether to enable HA mode."
  default     = true
}

variable "raft_storage_size" {
  type        = string
  description = "Persistent volume size for Raft storage."
  default     = "10Gi"
}

variable "raft_storage_class" {
  type        = string
  description = "StorageClass used by Raft PVCs."
  default     = "longhorn"
}

variable "injector_enabled" {
  type        = bool
  description = "Enable Vault Agent Injector for Kubernetes workloads."
  default     = true
}

variable "ingress" {
  description = "Ingress configuration for Vault HTTP endpoint."
  type = object({
    enabled         = bool
    hostname        = string
    tls_secret_name = string
    annotations     = map(string)
  })
  default = {
    enabled         = true
    hostname        = "vault.apps.example.com"
    tls_secret_name = "vault-tls"
    annotations     = {}
  }
}

variable "extra_values" {
  description = "Custom Helm values deep-merged on top of defaults."
  type        = map(any)
  default     = {}
}
