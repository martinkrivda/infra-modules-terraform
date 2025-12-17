variable "realms" {
  description = "Map of Keycloak realms to configure (clients, roles)."
  type = map(object({
    enabled      = optional(bool, true)
    display_name = optional(string)
    login_theme  = optional(string)
    roles = optional(map(object({
      description = optional(string)
    })), {})
    clients = optional(map(object({
      client_id                    = optional(string)
      name                         = optional(string)
      enabled                      = optional(bool)
      access_type                  = optional(string)
      root_url                     = optional(string)
      base_url                     = optional(string)
      admin_url                    = optional(string)
      web_origins                  = optional(list(string))
      redirect_uris                = optional(list(string))
      client_secret                = optional(string)
      service_accounts_enabled     = optional(bool)
      implicit_flow_enabled        = optional(bool)
      standard_flow_enabled        = optional(bool)
      direct_access_grants_enabled = optional(bool)
    })), {})
  }))
  default = {}
}
