resource "vault_kv_secret_v2" "app_user" {
  mount = var.vault_mount
  name  = "${local.app_secret_prefix}/databases/postgres"

  data_json = jsonencode({
    username = var.app_user_name
    password = local.app_user_password
    database = var.database_name
    host     = var.db_host
    port     = var.db_port
  })
}

resource "vault_kv_secret_v2" "admin_users" {
  for_each = var.admin_users

  mount = var.vault_mount
  name  = "${local.admin_secret_prefix}/admins/postgres/${each.key}"

  data_json = jsonencode({
    username = each.key
    password = local.admin_passwords[each.key]
    database = local.admin_grant_database[each.key]
    host     = var.db_host
    port     = var.db_port
    scope    = local.admin_user_scopes[each.key]
  })
}
