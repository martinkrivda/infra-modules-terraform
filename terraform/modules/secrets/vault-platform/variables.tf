variable "vault_address" {
  description = "Existing Vault API and public UI URL, with a trusted TLS certificate."
  type        = string

  validation {
    condition     = can(regex("^https://[^/?#]+/?$", var.vault_address))
    error_message = "vault_address must be an HTTPS origin without a path, query or fragment."
  }
}

variable "oidc_enabled" {
  description = "Enable OIDC only after the identity provider is running; false for the first bootstrap."
  type        = bool
  default     = false
}

variable "oidc_client_secret" {
  description = "Secret of the OIDC client; supply through TF_VAR_oidc_client_secret."
  type        = string
  sensitive   = true
  ephemeral   = true
  default     = null

  validation {
    condition     = !var.oidc_enabled || try(length(trimspace(var.oidc_client_secret)) > 0, false)
    error_message = "The OIDC client secret must not be empty."
  }
}

variable "oidc_client_secret_version" {
  description = "Increment whenever the write-only Keycloak client secret is rotated."
  type        = number
  default     = 1

  validation {
    condition     = var.oidc_client_secret_version >= 1 && floor(var.oidc_client_secret_version) == var.oidc_client_secret_version
    error_message = "The secret version must be a positive integer."
  }
}

variable "kubernetes_host" {
  description = "Kubernetes API reachable FROM the Vault pod; local rotating reviewer token and CA are used."
  type        = string
  default     = "https://kubernetes.default.svc:443"

  validation {
    condition     = can(regex("^https://[^/?#]+/?$", var.kubernetes_host))
    error_message = "kubernetes_host must be an HTTPS origin."
  }
}

variable "kubernetes_roles" {
  description = "Exact service account/namespace and KV v2 API read paths per workload; audiences must match the issued service account JWT."
  type = map(object({
    service_account = string
    namespace       = string
    read_paths      = set(string)
    audience        = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([for name, role in var.kubernetes_roles :
      can(regex("^[a-z0-9][a-z0-9-]*$", name)) &&
      can(regex("^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$", role.service_account)) &&
      role.service_account != "default" &&
      can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", role.namespace)) &&
      length(role.read_paths) > 0 &&
      alltrue([for path in role.read_paths :
        can(regex("^[a-zA-Z0-9_-]+/data/[a-zA-Z0-9_-]+(/[a-zA-Z0-9_-]+)+(/\\*)?$", path))
      ])
    ])
    error_message = "Roles must bind a named, non-default service account and one namespace; use scoped mount/data/... paths (optional trailing /*)."
  }
}

variable "kubernetes_auth_path" {
  description = "Vault Kubernetes authentication mount path."
  type        = string
  default     = "kubernetes"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.kubernetes_auth_path))
    error_message = "Use a simple auth mount name."
  }
}

variable "workload_policy_prefix" {
  description = "Prefix of read-only workload policies; retain during migration."
  type        = string
  default     = "k8s-"
}

variable "oidc_path" {
  description = "OIDC authentication mount path."
  type        = string
  default     = "oidc"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.oidc_path))
    error_message = "Use a simple auth mount name."
  }
}

variable "oidc_client_id" {
  description = "OIDC client ID and required audience."
  type        = string
  default     = "vault"
}

variable "oidc_admin_role_name" {
  description = "OIDC administrator login role name."
  type        = string
  default     = "admin"
}

variable "oidc_admin_group" {
  description = "Exact groups claim and external identity group granting full administration."
  type        = string
  default     = "vault-admins"
}

variable "oidc_admin_policy_name" {
  description = "Full-administration policy name."
  type        = string
  default     = "super-admin"
}

variable "oidc_discovery_url" {
  description = "HTTPS issuer URL, required when OIDC is enabled."
  type        = string
  default     = null
  validation {
    condition     = !var.oidc_enabled || can(regex("^https://", var.oidc_discovery_url))
    error_message = "Enabling OIDC requires an HTTPS issuer URL."
  }
}

variable "kv_mounts" {
  description = "KV v2 mounts and retention; secret values are filled separately."
  type = map(object({
    description          = optional(string, "Platform secrets")
    max_versions         = optional(number, 10)
    cas_required         = optional(bool, false)
    delete_version_after = optional(number, 0)
  }))
  default = {}
  validation {
    condition = alltrue([for path, settings in var.kv_mounts :
      can(regex("^[a-zA-Z0-9_-]+$", path)) &&
      settings.max_versions >= 1 && floor(settings.max_versions) == settings.max_versions &&
      settings.delete_version_after >= 0
    ])
    error_message = "Use simple mount names, positive integer retention and nonnegative deletion durations."
  }
}

variable "oidc_application_access" {
  description = "Independent OIDC groups mapped to selected KV v2 secrets. manage adds version writes and recoverable deletion, never permanent destruction."
  type = map(object({
    group_name    = string
    kv_mount      = string
    secret_prefix = string
    secret_names  = set(string)
    access        = optional(string, "read")
  }))
  default = {}

  validation {
    condition = alltrue([for name, access in var.oidc_application_access :
      can(regex("^[a-z0-9][a-z0-9-]*$", name)) && name != var.oidc_admin_role_name &&
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]*$", access.group_name)) && access.group_name != var.oidc_admin_group &&
      contains(keys(var.kv_mounts), access.kv_mount) &&
      can(regex("^[a-zA-Z0-9_-]+(/[a-zA-Z0-9_-]+)+$", access.secret_prefix)) &&
      length(access.secret_names) > 0 &&
      alltrue([for secret in access.secret_names : can(regex("^[a-zA-Z0-9_-]+$", secret))]) &&
      contains(["read", "manage"], access.access)
    ])
    error_message = "Use non-admin roles/groups, a managed KV mount, an explicit prefix and secret names without wildcards, and read/manage access."
  }
  validation {
    condition     = length(distinct([for access in values(var.oidc_application_access) : access.group_name])) == length(var.oidc_application_access)
    error_message = "Each application group must map to exactly one access definition."
  }
}
