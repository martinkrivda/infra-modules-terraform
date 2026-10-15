output "oidc_redirect_uris" {
  description = "Callback URLs to register with the identity provider."
  value       = local.oidc_redirect_uris
}

output "oidc_path" {
  description = "OIDC authentication path, or null when disabled."
  value       = try(vault_jwt_auth_backend.oidc[0].path, null)
}

output "kubernetes_auth_path" {
  description = "Kubernetes authentication path used by workload consumers."
  value       = vault_auth_backend.kubernetes.path
}

output "kubernetes_roles" {
  description = "Role bindings and policies, excluding token or secret values."
  value = { for name, role in vault_kubernetes_auth_backend_role.workload : name => {
    service_accounts = role.bound_service_account_names
    namespaces       = role.bound_service_account_namespaces
    policies         = role.token_policies
  } }
}

output "kv_mounts" {
  description = "Sorted KV v2 mount names."
  value       = sort(keys(vault_mount.kv))
}

output "oidc_application_roles" {
  description = "Application login roles, groups and policies, without credentials."
  value = { for name, role in vault_jwt_auth_backend_role.applications : name => {
    group_name = var.oidc_application_access[name].group_name
    policies   = vault_identity_group.applications[name].policies
    login_role = role.role_name
  } }
}
