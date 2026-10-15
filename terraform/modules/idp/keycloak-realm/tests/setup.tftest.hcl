mock_provider "keycloak" {}

variables {
  realm_name         = "test"
  realm_display_name = "Test SSO"
  groups             = ["admins", "readers"]
  realm_roles        = ["admin"]
  group_realm_roles  = { admins = ["admin"] }
  clients = [
    {
      client_id           = "web"
      valid_redirect_uris = ["https://app.example.com/callback"]
    },
    {
      client_id           = "spa"
      access_type         = "PUBLIC"
      valid_redirect_uris = ["https://spa.example.com/callback"]
    },
  ]
  users = [{
    username         = "test.user"
    email            = "test@example.com"
    first_name       = "Test"
    last_name        = "User"
    group_names      = ["admins"]
    required_actions = ["UPDATE_PASSWORD", "CONFIGURE_TOTP"]
  }]
}

run "realm_and_access" {
  command = apply

  assert {
    condition = (
      keycloak_realm.realm.ssl_required == "external" &&
      !keycloak_realm.realm.duplicate_emails_allowed &&
      keycloak_realm.realm.password_policy == "length(14) and notUsername(undefined) and notEmail(undefined) and passwordHistory(5)" &&
      !keycloak_realm.realm.security_defenses[0].brute_force_detection[0].permanent_lockout &&
      keycloak_realm.realm.security_defenses[0].brute_force_detection[0].max_login_failures == 5 &&
      keycloak_realm.realm.security_defenses[0].brute_force_detection[0].wait_increment_seconds == 60 &&
      keycloak_realm.realm.security_defenses[0].brute_force_detection[0].max_failure_wait_seconds == 900
    )
    error_message = "Realm must enforce HTTPS externally, unique emails, password policy and temporary brute-force lockout."
  }

  assert {
    condition = (
      keycloak_realm.realm.otp_policy[0].type == "totp" &&
      keycloak_realm.realm.otp_policy[0].period == 30 &&
      keycloak_realm.realm.otp_policy[0].digits == 6 &&
      toset(keycloak_user.users["test.user"].required_actions) == toset(["UPDATE_PASSWORD", "CONFIGURE_TOTP"]) &&
      !keycloak_user.users["test.user"].email_verified &&
      length(keycloak_user.users["test.user"].initial_password) == 0
    )
    error_message = "Bootstrap must require password change and TOTP, without storing a user password or auto-verifying email."
  }

  assert {
    condition     = !keycloak_realm.realm.registration_allowed && !keycloak_realm.realm.reset_password_allowed && length(keycloak_realm.realm.smtp_server) == 0
    error_message = "Without SMTP, self-registration and email password reset must be disabled."
  }

  assert {
    condition     = toset(keycloak_user_groups.users["test.user"].group_ids) == toset([keycloak_group.groups["admins"].id])
    error_message = "Users must receive only their declared group memberships."
  }

  assert {
    condition     = toset(keycloak_group_roles.groups["admins"].role_ids) == toset([keycloak_role.realm_roles["admin"].id])
    error_message = "Groups must receive the declared realm roles."
  }

  assert {
    condition = alltrue([
      for client in keycloak_openid_client.clients :
      client.standard_flow_enabled && !client.direct_access_grants_enabled && !client.implicit_flow_enabled && !client.service_accounts_enabled
    ])
    error_message = "Interactive clients must use the authorization code flow without password, implicit or service-account grants."
  }

  assert {
    condition     = keycloak_openid_client.clients["spa"].pkce_code_challenge_method == "S256" && toset(keys(output.client_secrets)) == toset(["web"])
    error_message = "Public clients must require PKCE and must not expose client secrets."
  }

  assert {
    condition = alltrue([
      for scopes in keycloak_openid_client_default_scopes.clients :
      contains(scopes.default_scopes, "groups") && contains(scopes.default_scopes, "email") && contains(scopes.default_scopes, "profile")
    ]) && keycloak_openid_group_membership_protocol_mapper.groups.add_to_id_token && keycloak_openid_group_membership_protocol_mapper.groups.add_to_access_token && keycloak_openid_group_membership_protocol_mapper.groups.add_to_userinfo && !keycloak_openid_group_membership_protocol_mapper.groups.full_path
    error_message = "All clients must get identity scopes and plain group names in ID/access tokens and userinfo."
  }
}

run "smtp_enables_password_reset" {
  command = plan

  variables {
    smtp_server = {
      host = "smtp.example.com"
      from = "sso@example.com"
      auth = {
        username = "test"
        password = "test-only-password"
      }
    }
  }

  assert {
    condition     = keycloak_realm.realm.reset_password_allowed && length(keycloak_realm.realm.smtp_server) == 1 && keycloak_realm.realm.smtp_server[0].starttls
    error_message = "SMTP must enable password reset and default to STARTTLS."
  }
}

run "reject_unrestricted_redirect" {
  command = plan

  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["*"]
    }]
  }

  expect_failures = [var.clients]
}

run "reject_redirect_path_wildcard" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://app.example.com/*"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_redirect_host_wildcard" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://*.example.com/callback"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_redirect_embedded_wildcard" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://app.example.com/call*back"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_redirect_encoded_wildcard" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://app.example.com/%2A"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_redirect_remote_http" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["http://app.example.com/callback"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_redirect_javascript" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["javascript:alert(1)"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_redirect_scheme_relative" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["//app.example.com/callback"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_redirect_userinfo" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://app.example.com@evil.example/callback"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_redirect_fragment" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://app.example.com/callback#fragment"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_redirect_backslash" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://app.example.com/\\evil.example"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_redirect_space" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://app.example.com/call back"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_redirect_non_vault_localhost" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["http://localhost:8250/oidc/callback"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_logout_wildcard" {
  command = plan
  variables {
    clients = [{
      client_id                       = "invalid"
      valid_redirect_uris             = ["https://app.example.com/callback"]
      valid_post_logout_redirect_uris = ["https://app.example.com/*"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_logout_http" {
  command = plan
  variables {
    clients = [{
      client_id                       = "invalid"
      valid_redirect_uris             = ["https://app.example.com/callback"]
      valid_post_logout_redirect_uris = ["http://app.example.com/"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_logout_plus" {
  command = plan
  variables {
    clients = [{
      client_id                       = "invalid"
      valid_redirect_uris             = ["https://app.example.com/callback"]
      valid_post_logout_redirect_uris = ["+"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_logout_scheme" {
  command = plan
  variables {
    clients = [{
      client_id                       = "invalid"
      valid_redirect_uris             = ["https://app.example.com/callback"]
      valid_post_logout_redirect_uris = ["data:text/plain,bye"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_origin_wildcard" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://app.example.com/callback"]
      web_origins         = ["https://*.example.com"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_origin_plus" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://app.example.com/callback"]
      web_origins         = ["+"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_origin_http" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://app.example.com/callback"]
      web_origins         = ["http://app.example.com"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_origin_path" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://app.example.com/callback"]
      web_origins         = ["https://app.example.com/path"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_origin_query" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://app.example.com/callback"]
      web_origins         = ["https://app.example.com?next=evil"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_origin_userinfo" {
  command = plan
  variables {
    clients = [{
      client_id           = "invalid"
      valid_redirect_uris = ["https://app.example.com/callback"]
      web_origins         = ["https://user@app.example.com"]
    }]
  }
  expect_failures = [var.clients]
}

run "reject_vault_other_port" {
  command = plan
  variables {
    clients = [{ client_id = "vault", valid_redirect_uris = ["http://localhost:8251/oidc/callback"] }]
  }
  expect_failures = [var.clients]
}

run "reject_vault_remote_http" {
  command = plan
  variables {
    clients = [{ client_id = "vault", valid_redirect_uris = ["http://vault.martinkrivda.cz/ui/vault/auth/oidc/oidc/callback"] }]
  }
  expect_failures = [var.clients]
}

run "reject_vault_localhost_suffix" {
  command = plan
  variables {
    clients = [{ client_id = "vault", valid_redirect_uris = ["http://localhost.evil.example:8250/oidc/callback"] }]
  }
  expect_failures = [var.clients]
}

run "accept_vault_cli_and_explicit_origins" {
  command = plan
  variables {
    clients = [{
      client_id                       = "vault"
      pkce_required                   = true
      valid_redirect_uris             = ["https://vault.example.com/ui/vault/auth/oidc/oidc/callback", "http://localhost:8250/oidc/callback"]
      valid_post_logout_redirect_uris = ["https://vault.example.com/"]
      web_origins                     = ["https://vault.example.com", "https://vault.example.com:8443"]
    }]
  }
  assert {
    condition     = keycloak_openid_client.clients["vault"].pkce_code_challenge_method == "S256"
    error_message = "Confidential consumers must support explicitly opting into S256."
  }
}

run "reject_unknown_user_group" {
  command = plan
  variables {
    users = [{ username = "test.user", email = "test@example.com", first_name = "Test", last_name = "User", group_names = ["typo"] }]
  }
  expect_failures = [keycloak_realm.realm]
}

run "reject_unknown_role_group" {
  command = plan
  variables {
    group_realm_roles = { typo = ["admin"] }
  }
  expect_failures = [keycloak_realm.realm]
}

run "reject_unknown_realm_role" {
  command = plan
  variables {
    group_realm_roles = { admins = ["typo"] }
  }
  expect_failures = [keycloak_realm.realm]
}

run "reject_empty_redirects" {
  command = plan
  variables {
    clients = [{ client_id = "empty", valid_redirect_uris = [] }]
  }
  expect_failures = [var.clients]
}

run "reject_duplicate_clients" {
  command = plan
  variables {
    clients = [
      { client_id = "duplicate", valid_redirect_uris = ["https://app.example.com/callback"] },
      { client_id = "duplicate", valid_redirect_uris = ["https://app.example.com/other"] },
    ]
  }
  expect_failures = [var.clients]
}

run "reject_bearer_only_interactive_client" {
  command = plan
  variables {
    clients = [{ client_id = "invalid", access_type = "BEARER-ONLY", valid_redirect_uris = ["https://app.example.com/callback"] }]
  }
  expect_failures = [var.clients]
}

run "reject_duplicate_users" {
  command = plan
  variables {
    users = [
      { username = "duplicate", email = "one@example.com", first_name = "Test", last_name = "One" },
      { username = "duplicate", email = "two@example.com", first_name = "Test", last_name = "Two" },
    ]
  }
  expect_failures = [var.users]
}
