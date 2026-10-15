locals {
  clients_by_id = { for client in var.clients : client.client_id => client }
  users_by_name = { for user in var.users : user.username => user }
}

resource "keycloak_realm" "realm" {
  realm                    = var.realm_name
  enabled                  = true
  display_name             = var.realm_display_name
  login_theme              = var.realm_login_theme
  registration_allowed     = false
  reset_password_allowed   = var.smtp_server != null
  login_with_email_allowed = true
  duplicate_emails_allowed = false
  ssl_required             = "external"
  password_policy          = "length(14) and notUsername(undefined) and notEmail(undefined) and passwordHistory(5)"

  security_defenses {
    brute_force_detection {
      permanent_lockout                = false
      max_login_failures               = 5
      wait_increment_seconds           = 60
      max_failure_wait_seconds         = 900
      quick_login_check_milli_seconds  = 1000
      minimum_quick_login_wait_seconds = 60
      failure_reset_time_seconds       = 43200
    }
  }

  otp_policy {
    type              = "totp"
    algorithm         = "HmacSHA1"
    digits            = 6
    initial_counter   = 0
    look_ahead_window = 1
    period            = 30
  }

  lifecycle {
    precondition {
      condition     = alltrue([for user in var.users : length(setsubtract(user.group_names, var.groups)) == 0])
      error_message = "Every user group_names entry must reference a managed group."
    }
    precondition {
      condition     = length(setsubtract(toset(keys(var.group_realm_roles)), var.groups)) == 0
      error_message = "Every group_realm_roles key must reference a managed group."
    }
    precondition {
      condition     = alltrue([for roles in values(var.group_realm_roles) : length(setsubtract(roles, var.realm_roles)) == 0])
      error_message = "Every group role assignment must reference a managed realm role."
    }
  }

  dynamic "smtp_server" {
    for_each = var.smtp_server == null ? [] : [var.smtp_server]
    content {
      host              = smtp_server.value.host
      port              = smtp_server.value.port
      from              = smtp_server.value.from
      from_display_name = smtp_server.value.from_display_name
      starttls          = smtp_server.value.starttls
      ssl               = smtp_server.value.ssl

      auth {
        username = smtp_server.value.auth.username
        password = smtp_server.value.auth.password
      }
    }
  }
}

resource "keycloak_group" "groups" {
  for_each = var.groups

  realm_id = keycloak_realm.realm.id
  name     = each.value
}

resource "keycloak_role" "realm_roles" {
  for_each = var.realm_roles

  realm_id = keycloak_realm.realm.id
  name     = each.value
}

resource "keycloak_group_roles" "groups" {
  # Invalid references are rejected by the realm preconditions, before indexing.
  for_each = { for group, roles in var.group_realm_roles : group => roles if contains(var.groups, group) }

  realm_id   = keycloak_realm.realm.id
  group_id   = keycloak_group.groups[each.key].id
  role_ids   = [for role_name in each.value : keycloak_role.realm_roles[role_name].id if contains(var.realm_roles, role_name)]
  exhaustive = true
}

resource "keycloak_user" "users" {
  for_each = local.users_by_name

  realm_id         = keycloak_realm.realm.id
  username         = each.value.username
  email            = each.value.email
  email_verified   = each.value.email_verified
  first_name       = each.value.first_name
  last_name        = each.value.last_name
  enabled          = each.value.enabled
  required_actions = each.value.required_actions

  lifecycle {
    ignore_changes = [federated_identity]
  }
}

resource "keycloak_user_groups" "users" {
  for_each = local.users_by_name

  realm_id  = keycloak_realm.realm.id
  user_id   = keycloak_user.users[each.key].id
  group_ids = [for group_name in each.value.group_names : keycloak_group.groups[group_name].id if contains(var.groups, group_name)]
}
