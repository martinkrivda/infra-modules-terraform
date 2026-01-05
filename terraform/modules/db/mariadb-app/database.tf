resource "mysql_database" "app" {
  name                  = var.database_name
  default_character_set = var.database_character_set
  default_collation     = var.database_collation
}
