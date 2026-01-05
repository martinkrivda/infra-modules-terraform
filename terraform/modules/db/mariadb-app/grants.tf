resource "mysql_grant" "app_user" {
  user       = mysql_user.app.user
  host       = mysql_user.app.host
  database   = var.database_name
  table      = "*"
  privileges = local.app_user_privileges
}

resource "mysql_grant" "admins" {
  for_each = var.admin_users

  user       = mysql_user.admins[each.key].user
  host       = mysql_user.admins[each.key].host
  database   = local.admin_grant_database[each.key]
  table      = "*"
  privileges = local.admin_privileges
}

resource "mysql_grant" "existing_admins" {
  for_each = var.existing_admin_users

  user       = each.key
  host       = local.existing_admin_user_hosts[each.key]
  database   = local.existing_admin_grant_database[each.key]
  table      = "*"
  privileges = local.admin_privileges
}
