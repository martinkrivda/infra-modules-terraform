resource "postgresql_grant" "app_database" {
  database    = var.database_name
  role        = postgresql_role.app.name
  object_type = "database"
  privileges  = local.app_user_privileges
}

resource "postgresql_grant" "app_schema" {
  database    = var.database_name
  role        = postgresql_role.app.name
  schema      = var.schema_name
  object_type = "schema"
  privileges  = local.app_schema_privileges
}

resource "postgresql_grant" "admin_database" {
  for_each = local.admin_database_users

  database    = var.database_name
  role        = postgresql_role.admins[each.key].name
  object_type = "database"
  privileges  = local.admin_privileges
}

resource "postgresql_grant" "admin_schema" {
  for_each = local.admin_database_users

  database    = var.database_name
  role        = postgresql_role.admins[each.key].name
  schema      = var.schema_name
  object_type = "schema"
  privileges  = local.admin_schema_privileges
}
