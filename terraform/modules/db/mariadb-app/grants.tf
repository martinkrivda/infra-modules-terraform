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
