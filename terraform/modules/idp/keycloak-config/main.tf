terraform {
  required_version = ">= 1.5.0"
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = ">= 4.4.0"
    }
  }
}

locals {
  realm_roles = flatten([
    for realm_name, realm in var.realms : [
      for role_name, role in lookup(realm, "roles", {}) : {
        id          = "${realm_name}:${role_name}"
        realm       = realm_name
        name        = role_name
        description = lookup(role, "description", "")
      }
    ]
  ])

  role_map = { for role in local.realm_roles : role.id => role }

  clients = flatten([
    for realm_name, realm in var.realms : [
      for client_name, client in lookup(realm, "clients", {}) : {
        id     = "${realm_name}:${client_name}"
        realm  = realm_name
        name   = client_name
        config = client
      }
    ]
  ])

  client_map = { for client in local.clients : client.id => client }
}

resource "keycloak_realm" "realms" {
  for_each = var.realms

  realm        = each.key
  enabled      = lookup(each.value, "enabled", true)
  display_name = lookup(each.value, "display_name", each.key)
  login_theme  = lookup(each.value, "login_theme", null)
}

resource "keycloak_role" "realm_roles" {
  for_each = local.role_map

  realm_id    = keycloak_realm.realms[each.value.realm].id
  name        = each.value.name
  description = each.value.description
}

resource "keycloak_openid_client" "clients" {
  for_each = local.client_map

  realm_id                     = keycloak_realm.realms[each.value.realm].id
  client_id                    = lookup(each.value.config, "client_id", each.value.name)
  name                         = lookup(each.value.config, "name", each.value.name)
  enabled                      = lookup(each.value.config, "enabled", true)
  access_type                  = lookup(each.value.config, "access_type", "CONFIDENTIAL")
  standard_flow_enabled        = lookup(each.value.config, "standard_flow_enabled", true)
  implicit_flow_enabled        = lookup(each.value.config, "implicit_flow_enabled", false)
  service_accounts_enabled     = lookup(each.value.config, "service_accounts_enabled", false)
  direct_access_grants_enabled = lookup(each.value.config, "direct_access_grants_enabled", true)
  root_url                     = lookup(each.value.config, "root_url", null)
  base_url                     = lookup(each.value.config, "base_url", "/")
  web_origins                  = lookup(each.value.config, "web_origins", ["*"])
  valid_redirect_uris          = lookup(each.value.config, "redirect_uris", ["*"])
  admin_url                    = lookup(each.value.config, "admin_url", null)
  client_secret                = lookup(each.value.config, "client_secret", null)
}
