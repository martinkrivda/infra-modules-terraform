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

resource "postgresql_role" "app" {
  name     = var.app_user_name
  login    = true
  password = local.app_user_password
}

resource "postgresql_role" "admins" {
  for_each = var.admin_users

  name       = each.key
  login      = true
  password   = local.admin_passwords[each.key]
  superuser  = local.admin_user_scopes[each.key] == "global"
  createdb   = local.admin_user_scopes[each.key] == "global"
  createrole = local.admin_user_scopes[each.key] == "global"
}
