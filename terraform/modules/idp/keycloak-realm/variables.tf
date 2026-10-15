variable "realm_name" {
  description = "Name of the single managed realm; retain it during migration."
  type        = string
}

variable "realm_display_name" {
  description = "Display name shown on the login page."
  type        = string
}

variable "realm_login_theme" {
  description = "Optional installed login theme."
  type        = string
  default     = null
}

variable "smtp_server" {
  description = "Optional SMTP connection; its password is stored in Keycloak Terraform state."
  type = object({
    host              = string
    port              = optional(number, 587)
    from              = string
    from_display_name = optional(string)
    starttls          = optional(bool, true)
    ssl               = optional(bool, false)
    auth = object({
      username = string
      password = string
    })
  })
  default   = null
  sensitive = true
}

variable "groups" {
  description = "Managed top-level groups; claim values omit the leading slash."
  type        = set(string)
  default     = []
}

variable "clients" {
  description = "Interactive clients with explicit HTTPS callbacks; PUBLIC clients always require S256."
  type = list(object({
    client_id                       = string
    access_type                     = optional(string, "CONFIDENTIAL")
    pkce_required                   = optional(bool, false)
    valid_redirect_uris             = list(string)
    valid_post_logout_redirect_uris = optional(list(string), [])
    web_origins                     = optional(list(string), [])
  }))
  default = []

  validation {
    condition     = length(distinct([for client in var.clients : client.client_id])) == length(var.clients)
    error_message = "Client IDs must be unique."
  }

  validation {
    condition     = alltrue([for client in var.clients : contains(["CONFIDENTIAL", "PUBLIC"], client.access_type)])
    error_message = "Interactive OIDC clients must use CONFIDENTIAL or PUBLIC access."
  }

  validation {
    condition = alltrue([for client in var.clients : length(client.valid_redirect_uris) > 0 && alltrue([
      for uri in client.valid_redirect_uris :
      (can(regex("^https://[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*(:[0-9]{1,5})?(/[^\\s*#\\\\]*)?$", uri)) && !strcontains(lower(uri), "%2a")) ||
      (client.client_id == "vault" && uri == "http://localhost:8250/oidc/callback")
    ])])
    error_message = "Each client needs explicit HTTPS redirect URIs without wildcards, userinfo, fragments or whitespace. Only vault may use http://localhost:8250/oidc/callback."
  }

  validation {
    condition = alltrue(flatten([for client in var.clients : [
      for uri in client.valid_post_logout_redirect_uris :
      can(regex("^https://[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*(:[0-9]{1,5})?(/[^\\s*#\\\\]*)?$", uri)) && !strcontains(lower(uri), "%2a")
    ]]))
    error_message = "Logout redirects must be explicit HTTPS URIs without wildcards, userinfo, fragments or whitespace; '+' is not allowed."
  }

  validation {
    condition = alltrue(flatten([for client in var.clients : [
      for origin in client.web_origins :
      can(regex("^https://[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*(:[0-9]{1,5})?$", origin))
    ]]))
    error_message = "Web origins must be explicit HTTPS origins without paths, wildcards or '+'; leave empty when browser CORS is unnecessary."
  }
}

variable "realm_roles" {
  description = "Managed realm role names."
  type        = set(string)
  default     = []
}

variable "group_realm_roles" {
  description = "Group name to managed realm role names."
  type        = map(set(string))
  default     = {}
}

variable "users" {
  description = "User identities, memberships and bootstrap actions; no password input is accepted."
  type = list(object({
    username         = string
    email            = string
    email_verified   = optional(bool, false)
    first_name       = string
    last_name        = string
    enabled          = optional(bool, true)
    required_actions = optional(list(string), [])
    group_names      = optional(set(string), [])
  }))
  default = []

  validation {
    condition     = length(distinct([for user in var.users : user.username])) == length(var.users)
    error_message = "Usernames must be unique."
  }
}
