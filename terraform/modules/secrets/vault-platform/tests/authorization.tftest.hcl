mock_provider "vault" {}

variables {
  oidc_enabled               = true
  vault_address              = "https://vault.example.com"
  oidc_client_secret         = "test-only-not-a-real-secret"
  oidc_client_secret_version = 1
  kubernetes_host            = "https://kubernetes.default.svc:443"
  oidc_discovery_url         = "https://sso.example.com/realms/platform"
  workload_policy_prefix     = "k3s-"
  kv_mounts = {
    secret = {}
    apps   = {}
  }
  kubernetes_roles = {
    app = {
      service_account = "app-vault"
      namespace       = "app"
      read_paths      = ["apps/data/app/prod/api"]
      audience        = "vault"
    }
  }
}

run "authorization_boundaries" {
  command = plan

  assert {
    condition = (
      vault_jwt_auth_backend.oidc[0].oidc_discovery_url == "https://sso.example.com/realms/platform" &&
      vault_jwt_auth_backend.oidc[0].type == "oidc" &&
      one(vault_jwt_auth_backend.oidc[0].tune).listing_visibility == "unauth" &&
      vault_jwt_auth_backend_role.admin[0].bound_claims["groups"] == "vault-admins" &&
      vault_jwt_auth_backend_role.admin[0].bound_claims_type == "string" &&
      toset(vault_jwt_auth_backend_role.admin[0].bound_audiences) == toset(["vault"]) &&
      vault_jwt_auth_backend_role.admin[0].user_claim == "sub" &&
      vault_jwt_auth_backend_role.admin[0].groups_claim == "groups" &&
      length(vault_jwt_auth_backend_role.admin[0].token_policies) == 0 &&
      vault_identity_group.admins[0].type == "external" &&
      toset(vault_identity_group.admins[0].policies) == toset(["super-admin"]) &&
      vault_identity_group_alias.admins[0].name == "vault-admins"
    )
    error_message = "OIDC must require the exact admin group and client, granting admin rights only through group mapping."
  }

  assert {
    condition = (
      vault_kubernetes_auth_backend_config.k3s.disable_local_ca_jwt == false &&
      vault_kubernetes_auth_backend_role.workload["app"].audience == "vault" &&
      toset(vault_kubernetes_auth_backend_role.workload["app"].bound_service_account_names) == toset(["app-vault"]) &&
      toset(vault_kubernetes_auth_backend_role.workload["app"].bound_service_account_namespaces) == toset(["app"]) &&
      toset(vault_kubernetes_auth_backend_role.workload["app"].token_policies) == toset(["k3s-app"]) &&
      trimspace(vault_policy.workload["app"].policy) == trimspace(<<-EOT
        path "apps/data/app/prod/api" {
          capabilities = ["read"]
        }
      EOT
      )
    )
    error_message = "Workloads must use the local reviewer and receive only read access to their explicitly scoped secret paths."
  }

  assert {
    condition = (
      vault_jwt_auth_backend_role.admin[0].token_explicit_max_ttl == 3600 &&
      vault_kubernetes_auth_backend_role.workload["app"].token_explicit_max_ttl == 3600 &&
      vault_kubernetes_auth_backend_role.workload["app"].token_ttl == 600 &&
      vault_jwt_auth_backend_role.admin[0].verbose_oidc_logging == false &&
      vault_audit.stdout.options["log_raw"] == "false" &&
      vault_audit.stdout.options["hmac_accessor"] == "true" &&
      vault_audit.stdout.options["file_path"] == "stdout"
    )
    error_message = "Token lifetime must be bounded and audit logs must protect secret values."
  }

  assert {
    condition = alltrue([for mount in ["secret", "apps"] :
      vault_mount.kv[mount].options["version"] == "2" &&
      vault_kv_secret_backend_v2.kv[mount].max_versions == 10 &&
      vault_kv_secret_backend_v2.kv[mount].delete_version_after == 0 &&
      vault_kv_secret_backend_v2.kv[mount].cas_required == false
    ])
    error_message = "KV v2 retention must preserve recent versions and stay compatible with the existing filler."
  }
}
