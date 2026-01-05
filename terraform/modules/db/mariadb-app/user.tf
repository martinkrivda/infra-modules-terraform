resource "random_password" "app_user" {
  count = local.app_password_provided ? 0 : 1

  length  = 24
  special = true
}

resource "random_password" "admin_users" {
  for_each = {
    for name, cfg in var.admin_users : name => cfg
    if try(cfg.password, null) == null || try(cfg.password, "") == ""
  }

  length  = 24
  special = true
}

resource "mysql_user" "app" {
  user     = var.app_user_name
  host     = var.app_user_host
  plaintext_password = local.app_user_password
}

resource "mysql_user" "admins" {
  for_each = var.admin_users

  user     = each.key
  host     = local.admin_user_hosts[each.key]
  plaintext_password = local.admin_passwords[each.key]
}
