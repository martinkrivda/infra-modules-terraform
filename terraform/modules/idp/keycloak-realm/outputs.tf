output "realm_id" {
  value = keycloak_realm.realm.id
}

output "group_ids" {
  value = { for name, group in keycloak_group.groups : name => group.id }
}

output "client_ids" {
  value = { for client_id, client in keycloak_openid_client.clients : client_id => client.id }
}

output "client_secrets" {
  value = {
    for client_id, client in keycloak_openid_client.clients :
    client_id => client.client_secret if client.access_type == "CONFIDENTIAL"
  }
  sensitive = true
}

output "user_ids" {
  value = { for username, user in keycloak_user.users : username => user.id }
}

output "client_configuration" {
  description = "Non-secret OIDC settings for integration checks."
  value = { for name, client in keycloak_openid_client.clients : name => {
    client_id                       = client.client_id
    access_type                     = client.access_type
    valid_redirect_uris             = client.valid_redirect_uris
    valid_post_logout_redirect_uris = client.valid_post_logout_redirect_uris
    web_origins                     = client.web_origins
    standard_flow_enabled           = client.standard_flow_enabled
    implicit_flow_enabled           = client.implicit_flow_enabled
    direct_access_grants_enabled    = client.direct_access_grants_enabled
    service_accounts_enabled        = client.service_accounts_enabled
    pkce_code_challenge_method      = client.pkce_code_challenge_method
    default_scopes                  = keycloak_openid_client_default_scopes.clients[name].default_scopes
  } }
}

output "groups_claim" {
  description = "Group claim contract for OIDC consumers; contains no user data."
  value = {
    name                = keycloak_openid_group_membership_protocol_mapper.groups.claim_name
    full_path           = keycloak_openid_group_membership_protocol_mapper.groups.full_path
    add_to_id_token     = keycloak_openid_group_membership_protocol_mapper.groups.add_to_id_token
    add_to_access_token = keycloak_openid_group_membership_protocol_mapper.groups.add_to_access_token
    add_to_userinfo     = keycloak_openid_group_membership_protocol_mapper.groups.add_to_userinfo
  }
}

output "user_access" {
  description = "Managed group memberships and bootstrap actions; contains no credentials."
  value = { for username, user in keycloak_user.users : username => {
    group_ids        = keycloak_user_groups.users[username].group_ids
    required_actions = user.required_actions
  } }
}
