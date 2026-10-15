mock_provider "vault" {}
variables {
  vault_address      = "https://vault.example.com"
  oidc_enabled       = true
  oidc_discovery_url = "https://sso.example.com/realms/example"
  oidc_client_secret = "mock-only-not-a-credential"
  kv_mounts          = { secret = {} }
  oidc_application_access = {
    app-prod-managers = {
      group_name    = "vault-app-prod-managers", kv_mount = "secret",
      secret_prefix = "apps/prod/app", secret_names = ["server"], access = "manage"
    }
    app-test-readers = {
      group_name    = "vault-app-test-readers", kv_mount = "secret",
      secret_prefix = "apps/test/app", secret_names = ["server"], access = "read"
    }
  }
}
run "application_authorization" {
  command = apply
  assert {
    condition = alltrue([for name, role in vault_jwt_auth_backend_role.applications :
      role.bound_claims == tomap({ groups = var.oidc_application_access[name].group_name }) &&
      role.bound_claims_type == "string" && role.user_claim == "sub" && role.groups_claim == "groups" &&
      toset(role.bound_audiences) == toset(["vault"]) && length(role.token_policies) == 0 &&
      !role.verbose_oidc_logging &&
      vault_identity_group_alias.applications[name].canonical_id == vault_identity_group.applications[name].id &&
      vault_identity_group_alias.applications[name].mount_accessor == vault_jwt_auth_backend.oidc[0].accessor &&
      toset(vault_identity_group.applications[name].policies) == toset([vault_policy.oidc_applications[name].name])
    ])
    error_message = "Login must bind an exact group and use only its matching external identity policy."
  }
  assert {
    condition = (
      strcontains(vault_policy.oidc_applications["app-prod-managers"].policy, "secret/data/apps/prod/app/server") &&
      strcontains(vault_policy.oidc_applications["app-prod-managers"].policy, "secret/undelete/apps/prod/app/server") &&
      !strcontains(vault_policy.oidc_applications["app-prod-managers"].policy, "apps/test/") &&
      !strcontains(vault_policy.oidc_applications["app-test-readers"].policy, "apps/prod/") &&
      !strcontains(vault_policy.oidc_applications["app-test-readers"].policy, "update") &&
      alltrue([for policy in vault_policy.oidc_applications :
        !strcontains(policy.policy, "*") && !strcontains(policy.policy, "/destroy/") && !strcontains(policy.policy, "sudo")
      ])
    )
    error_message = "Application policies must separate environments and prevent wildcard, permanent-destroy or administrator access."
  }
}
run "reject_application_admin_group" {
  command = plan
  variables {
    oidc_application_access = { app = { group_name = "vault-admins", kv_mount = "secret", secret_prefix = "apps/prod/app", secret_names = ["server"] } }
  }
  expect_failures = [var.oidc_application_access]
}
run "reject_wildcard_secret" {
  command = plan
  variables {
    oidc_application_access = { app = { group_name = "vault-app", kv_mount = "secret", secret_prefix = "apps/prod/app", secret_names = ["*"] } }
  }
  expect_failures = [var.oidc_application_access]
}
run "reject_unscoped_prefix" {
  command = plan
  variables {
    oidc_application_access = { app = { group_name = "vault-app", kv_mount = "secret", secret_prefix = "*", secret_names = ["server"] } }
  }
  expect_failures = [var.oidc_application_access]
}
run "reject_unknown_mount" {
  command = plan
  variables {
    oidc_application_access = { app = { group_name = "vault-app", kv_mount = "unknown", secret_prefix = "apps/prod/app", secret_names = ["server"] } }
  }
  expect_failures = [var.oidc_application_access]
}
