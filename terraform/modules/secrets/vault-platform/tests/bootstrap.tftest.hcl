mock_provider "vault" {}

variables {
  vault_address = "https://vault.example.com"
  kv_mounts = {
    platform = { max_versions = 20, cas_required = true }
  }
  kubernetes_auth_path   = "workloads"
  workload_policy_prefix = "platform-"
  kubernetes_roles = {
    eso = {
      service_account = "external-secrets"
      namespace       = "secrets"
      read_paths      = ["platform/data/services/database"]
    }
  }
}

run "bootstrap_without_identity_provider" {
  command = plan
  assert {
    condition = (
      length(vault_jwt_auth_backend.oidc) == 0 &&
      length(vault_identity_group.admins) == 0 &&
      output.kubernetes_auth_path == "workloads" &&
      vault_kubernetes_auth_backend_config.k3s.disable_local_ca_jwt == false &&
      vault_kubernetes_auth_backend_role.workload["eso"].audience == null &&
      toset(vault_kubernetes_auth_backend_role.workload["eso"].token_policies) == toset(["platform-eso"]) &&
      vault_kv_secret_backend_v2.kv["platform"].max_versions == 20 &&
      vault_kv_secret_backend_v2.kv["platform"].cas_required == true &&
      toset(output.kv_mounts) == toset(["platform"])
    )
    error_message = "Bootstrap must support custom mounts and roles without contacting an identity provider."
  }
}

run "reject_unscoped_read" {
  command = plan
  variables {
    kubernetes_roles = {
      bad = { service_account = "eso", namespace = "secrets", read_paths = ["platform/data/*"] }
    }
  }
  expect_failures = [var.kubernetes_roles]
}

run "reject_default_account" {
  command = plan
  variables {
    kubernetes_roles = {
      bad = { service_account = "default", namespace = "secrets", read_paths = ["platform/data/services/database"] }
    }
  }
  expect_failures = [var.kubernetes_roles]
}

run "reject_missing_oidc_issuer" {
  command = plan
  variables {
    oidc_enabled       = true
    oidc_client_secret = "test-only-not-a-real-secret"
  }
  expect_failures = [var.oidc_discovery_url]
}
