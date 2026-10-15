resource "keycloak_openid_client" "clients" {
  for_each = local.clients_by_id

  realm_id                        = keycloak_realm.realm.id
  client_id                       = each.value.client_id
  name                            = each.value.client_id
  enabled                         = true
  access_type                     = each.value.access_type
  standard_flow_enabled           = true
  implicit_flow_enabled           = false
  direct_access_grants_enabled    = false
  service_accounts_enabled        = false
  pkce_code_challenge_method      = each.value.access_type == "PUBLIC" || each.value.pkce_required ? "S256" : null
  valid_redirect_uris             = each.value.valid_redirect_uris
  valid_post_logout_redirect_uris = each.value.valid_post_logout_redirect_uris
  web_origins                     = each.value.web_origins
}

resource "keycloak_openid_client_scope" "groups" {
  realm_id               = keycloak_realm.realm.id
  name                   = "groups"
  description            = "Group memberships for application authorization."
  include_in_token_scope = true
}

resource "keycloak_openid_group_membership_protocol_mapper" "groups" {
  realm_id            = keycloak_realm.realm.id
  client_scope_id     = keycloak_openid_client_scope.groups.id
  name                = "groups"
  claim_name          = "groups"
  full_path           = false
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}

resource "keycloak_openid_client_default_scopes" "clients" {
  for_each = local.clients_by_id

  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.clients[each.key].id
  default_scopes = [
    "profile",
    "email",
    "roles",
    "web-origins",
    keycloak_openid_client_scope.groups.name,
  ]
}
