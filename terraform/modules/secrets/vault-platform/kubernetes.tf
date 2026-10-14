resource "vault_auth_backend" "kubernetes" {
  type        = "kubernetes"
  path        = var.kubernetes_auth_path
  description = "Kubernetes workload authentication"

  tune {
    default_lease_ttl = "10m"
    max_lease_ttl     = "1h"
    token_type        = "default-service"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "vault_kubernetes_auth_backend_config" "k3s" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = var.kubernetes_host
  disable_local_ca_jwt   = false
  disable_iss_validation = true
  # Vault runs inside the target cluster. Omitting reviewer JWT and CA makes Vault
  # reload its own projected service account token and CA from the pod filesystem.
}

resource "vault_policy" "workload" {
  for_each = var.kubernetes_roles
  name     = "${var.workload_policy_prefix}${each.key}"
  policy = join("\n", [for path in sort(tolist(each.value.read_paths)) : <<-EOT
    path "${path}" {
      capabilities = ["read"]
    }
  EOT
  ])
}

resource "vault_kubernetes_auth_backend_role" "workload" {
  for_each                         = var.kubernetes_roles
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = each.key
  bound_service_account_names      = [each.value.service_account]
  bound_service_account_namespaces = [each.value.namespace]
  audience                         = each.value.audience
  token_policies                   = [vault_policy.workload[each.key].name]
  token_ttl                        = 600
  token_max_ttl                    = 3600
  token_explicit_max_ttl           = 3600
  token_type                       = "service"
  # Keep Vault's default self-service policy for Agent token lookup and renewal.
  token_no_default_policy = false

  depends_on = [vault_kubernetes_auth_backend_config.k3s]
}
