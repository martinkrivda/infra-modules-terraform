variable "namespace" {
  type    = string
  default = "argocd"
}

variable "chart_version" {
  type        = string
  description = "Helm chart version for ArgoCD"
  default     = "5.51.6" # příklad, můžeš změnit
}

# values_yaml = string s YAML configem (typicky file() v rootu)
variable "values_yaml" {
  type        = string
  description = "Helm values as YAML string"
  default     = ""
}
