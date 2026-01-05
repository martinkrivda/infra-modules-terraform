variable "database_name" {
  type        = string
  description = "MariaDB database name for the application."
}

variable "database_character_set" {
  type        = string
  description = "Default character set for the database."
  default     = "utf8mb4"
}

variable "database_collation" {
  type        = string
  description = "Default collation for the database."
  default     = "utf8mb4_general_ci"
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

variable "app_user_host" {
  type        = string
  description = "Host pattern for the app user (default %)."
  default     = "%"
}

variable "app_user_privileges" {
  type        = list(string)
  description = "Privileges granted to the app user on its database."
  default     = ["ALL PRIVILEGES"]
}

variable "admin_users" {
  description = "Admin users created alongside the app user. Scope can be database or global."
  type = map(object({
    password = optional(string)
    host     = optional(string)
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

variable "existing_admin_users" {
  type        = map(object({
    host  = optional(string)
    scope = optional(string)
  }))
  description = "Admin users that already exist in MariaDB. The module will only apply grants + Vault secrets."
  default     = {}

  validation {
    condition = alltrue([
      for _, cfg in var.existing_admin_users :
      contains(["database", "global"], coalesce(try(cfg.scope, null), "database"))
    ])
    error_message = "existing_admin_users.scope must be either 'database' or 'global'."
  }
}

variable "admin_privileges" {
  type        = list(string)
  description = "Privileges granted to admin users."
  default     = ["ALL PRIVILEGES"]
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
  description = "MariaDB hostname or service name stored in Vault."
}

variable "db_port" {
  type        = number
  description = "MariaDB port stored in Vault."
  default     = 3306
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
