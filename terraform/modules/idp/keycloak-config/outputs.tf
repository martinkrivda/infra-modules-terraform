output "realm_ids" {
  description = "Map of configured realms and their IDs."
  value       = { for realm, resource in keycloak_realm.realms : realm => resource.id }
}

output "client_ids" {
  description = "Map of configured clients and their Keycloak IDs."
  value       = { for key, client in keycloak_openid_client.clients : key => client.id }
}
