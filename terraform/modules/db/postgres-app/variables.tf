variable "database_name" {
  type        = string
  description = "PostgreSQL database name for the application."
}

variable "schema_name" {
  type        = string
  description = "Schema name for application grants."
  default     = "public"
}

variable "app_user_name" {
  type        = string
  description = "Application database username."
}

variable "app_user_password" {
  type        = string
  description = "Optional app user password. When null/empty, a random one is generated."
  default     = null
  sensitive   = true
}

variable "app_user_privileges" {
  type        = list(string)
  description = "Database privileges granted to the app user."
  default     = null
}

variable "app_schema_privileges" {
  type        = list(string)
  description = "Schema privileges granted to the app user."
  default     = null
}

variable "admin_users" {
  description = "Admin users created alongside the app user. Scope can be database or global."
  type = map(object({
    password = optional(string)
    scope    = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for _, cfg in var.admin_users :
      contains(["database", "global"], coalesce(try(cfg.scope, null), "database"))
    ])
    error_message = "admin_users.scope must be either 'database' or 'global'."
  }
}

variable "admin_privileges" {
  type        = list(string)
  description = "Database privileges granted to admin users."
  default     = null
}

variable "admin_schema_privileges" {
  type        = list(string)
  description = "Schema privileges granted to admin users."
  default     = null
}

variable "environment" {
  type        = string
  description = "Environment name (dev, stage, prod)."
}

variable "app_group" {
  type        = string
  description = "Application group/client/namespace (e.g. ofeed, claudox, kobchocen)."
}

variable "app_name" {
  type        = string
  description = "Application identifier within the group."
}

variable "db_host" {
  type        = string
  description = "PostgreSQL hostname or service name stored in Vault."
}

variable "db_port" {
  type        = number
  description = "PostgreSQL port stored in Vault."
  default     = 5432
}

variable "vault_mount" {
  type        = string
  description = "Vault KV v2 mount path used for database secrets."
  default     = "apps"
}

variable "vault_app_secret_prefix" {
  type        = string
  description = "Override for the app secret prefix inside the KV mount."
  default     = null
}

variable "vault_admin_secret_prefix" {
  type        = string
  description = "Override for the admin secret prefix inside the KV mount."
  default     = null
}
