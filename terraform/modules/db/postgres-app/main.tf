terraform {
  required_version = ">= 1.5.0"
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.22.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 3.20.0"
    }
  }
}

locals {
  app_password_provided = var.app_user_password != null && var.app_user_password != ""
  app_user_password     = local.app_password_provided ? var.app_user_password : random_password.app_user[0].result

  app_secret_prefix   = coalesce(var.vault_app_secret_prefix, "${var.app_group}/${var.environment}/${var.app_name}")
  admin_secret_prefix = coalesce(var.vault_admin_secret_prefix, "${var.app_group}/${var.environment}")

  admin_user_scopes = {
    for name, cfg in var.admin_users : name => coalesce(try(cfg.scope, null), "database")
  }

  admin_database_users = {
    for name, cfg in var.admin_users : name => cfg
    if local.admin_user_scopes[name] == "database"
  }

  admin_passwords_provided = {
    for name, cfg in var.admin_users :
    name => (try(cfg.password, null) != null && try(cfg.password, "") != "")
  }

  admin_passwords = {
    for name, cfg in var.admin_users :
    name => local.admin_passwords_provided[name] ? cfg.password : random_password.admin_users[name].result
  }

  admin_grant_database = {
    for name, scope in local.admin_user_scopes :
    name => scope == "global" ? "postgres" : var.database_name
  }

  app_user_privileges     = var.app_user_privileges != null ? var.app_user_privileges : ["ALL"]
  admin_privileges        = var.admin_privileges != null ? var.admin_privileges : ["ALL"]
  app_schema_privileges   = var.app_schema_privileges != null ? var.app_schema_privileges : ["USAGE", "CREATE"]
  admin_schema_privileges = var.admin_schema_privileges != null ? var.admin_schema_privileges : ["USAGE", "CREATE"]

  generated_admin_passwords = {
    for name, provided in local.admin_passwords_provided :
    name => random_password.admin_users[name].result
    if !provided
  }
}
