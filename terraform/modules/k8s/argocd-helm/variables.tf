variable "release_name" {
  type        = string
  description = "Helm release name."
  default     = "argocd"
}

variable "namespace" {
  type        = string
  description = "Namespace where Argo CD will be installed."
  default     = "argocd"
}

variable "repository" {
  type        = string
  description = "Helm repository URL."
  default     = "https://argoproj.github.io/argo-helm"
}

variable "chart" {
  type        = string
  description = "Chart name inside the repository."
  default     = "argo-cd"
}

variable "chart_version" {
  type        = string
  description = "Specific Argo CD chart version."
  default     = "6.9.2"
}

variable "values" {
  description = "Additional Helm values merged into the release."
  type        = any
  default     = null
}

variable "bootstrap_projects" {
  description = "Optional list of AppProjects to seed inside the Argo CD namespace."
  type = list(object({
    name                = string
    description         = optional(string)
    annotations         = optional(map(string))
    source_repositories = list(string)
    destinations = list(object({
      namespace = string
      server    = string
    }))
    cluster_resource_whitelist = optional(list(object({
      group = string
      kind  = string
    })), [])
  }))
  default = []
}

variable "bootstrap_applications" {
  description = "Optional list of Argo CD Applications to bootstrap via GitOps."
  type = list(object({
    name                  = string
    project               = string
    repo_url              = string
    path                  = string
    revision              = string
    destination_namespace = string
    destination_server    = string
    helm = optional(object({
      value_files = list(string)
    }))
    sync_policy = object({
      automated = bool
      prune     = bool
      self_heal = bool
      options   = optional(list(string), [])
    })
  }))
  default = []
}
