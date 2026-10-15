# Test files have independent state. Keep disabled-OIDC bootstrap separate from
# application_authorization, whose mock apply creates a protected auth backend.
mock_provider "vault" {}

variables {
  vault_address = "https://vault.example.com"
  kv_mounts     = { secret = {} }
  oidc_application_access = {
    app-prod-managers = {
      group_name    = "vault-app-prod-managers"
      kv_mount      = "secret"
      secret_prefix = "apps/prod/app"
      secret_names  = ["server"]
      access        = "manage"
    }
  }
}

run "bootstrap_has_no_application_roles" {
  command = plan

  assert {
    condition = (
      length(vault_jwt_auth_backend.oidc) == 0 &&
      length(vault_policy.oidc_applications) == 0 &&
      length(vault_jwt_auth_backend_role.applications) == 0 &&
      length(vault_identity_group.applications) == 0 &&
      length(vault_identity_group_alias.applications) == 0 &&
      length(output.oidc_application_roles) == 0
    )
    error_message = "Bootstrap without OIDC must not create an auth backend or application policies, roles, groups or aliases, even when application access is configured."
  }
}
