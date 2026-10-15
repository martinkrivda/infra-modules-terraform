locals {
  oidc_application_access = var.oidc_enabled ? var.oidc_application_access : {}
}

resource "vault_policy" "oidc_applications" {
  for_each = local.oidc_application_access
  name     = "oidc-${each.key}"
  policy = join("\n", concat(
    [for name in sort(tolist(each.value.secret_names)) : <<-POLICY
      path "${each.value.kv_mount}/data/${each.value.secret_prefix}/${name}" {
        capabilities = ${jsonencode(each.value.access == "manage" ? ["create", "read", "update", "patch", "delete"] : ["read"])}
      }
      path "${each.value.kv_mount}/metadata/${each.value.secret_prefix}/${name}" {
        capabilities = ["read"]
      }
      POLICY
    ],
    [<<-POLICY
      path "${each.value.kv_mount}/metadata/${each.value.secret_prefix}" {
        capabilities = ["list"]
      }
      POLICY
    ],
    each.value.access == "manage" ? [for name in sort(tolist(each.value.secret_names)) : <<-POLICY
      path "${each.value.kv_mount}/undelete/${each.value.secret_prefix}/${name}" {
        capabilities = ["update"]
      }
      POLICY
    ] : []
  ))
}

resource "vault_jwt_auth_backend_role" "applications" {
  for_each               = local.oidc_application_access
  backend                = vault_jwt_auth_backend.oidc[0].path
  role_name              = each.key
  role_type              = "oidc"
  user_claim             = "sub"
  groups_claim           = "groups"
  oidc_scopes            = ["profile", "email", "groups"]
  bound_audiences        = [var.oidc_client_id]
  bound_claims_type      = "string"
  bound_claims           = { groups = each.value.group_name }
  allowed_redirect_uris  = local.oidc_redirect_uris
  token_policies         = []
  token_ttl              = 900
  token_max_ttl          = 3600
  token_explicit_max_ttl = 3600
  token_type             = "service"
  verbose_oidc_logging   = false
}

resource "vault_identity_group" "applications" {
  for_each = local.oidc_application_access
  name     = each.value.group_name
  type     = "external"
  policies = [vault_policy.oidc_applications[each.key].name]
}

resource "vault_identity_group_alias" "applications" {
  for_each       = local.oidc_application_access
  name           = each.value.group_name
  mount_accessor = vault_jwt_auth_backend.oidc[0].accessor
  canonical_id   = vault_identity_group.applications[each.key].id
}
