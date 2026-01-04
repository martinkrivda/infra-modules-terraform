output "database" {
  description = "Database name managed by the module."
  value       = mysql_database.app.name
}

output "app_user" {
  description = "App database username."
  value       = mysql_user.app.user
}

output "app_user_password" {
  description = "Generated app user password when not provided."
  value       = local.app_password_provided ? null : random_password.app_user[0].result
  sensitive   = true
}

output "admin_users" {
  description = "Admin users created by the module."
  value       = keys(var.admin_users)
}

output "generated_admin_passwords" {
  description = "Generated admin passwords (only for users without provided password)."
  value       = local.generated_admin_passwords
  sensitive   = true
}

output "vault_app_user_secret_path" {
  description = "Vault KV v2 path (relative to mount) for the app user secret."
  value       = vault_kv_secret_v2.app_user.name
}

output "vault_admin_secret_paths" {
  description = "Vault KV v2 paths (relative to mount) for admin secrets."
  value       = { for name, secret in vault_kv_secret_v2.admin_users : name => secret.name }
}
