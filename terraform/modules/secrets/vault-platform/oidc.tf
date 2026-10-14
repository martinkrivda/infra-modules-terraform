locals {
  oidc_redirect_uris = [
    "${trimsuffix(var.vault_address, "/")}/ui/vault/auth/${var.oidc_path}/oidc/callback",
    "http://localhost:8250/oidc/callback",
  ]
}

resource "vault_jwt_auth_backend" "oidc" {
  count                         = var.oidc_enabled ? 1 : 0
  path                          = var.oidc_path
  type                          = "oidc"
  description                   = "Platform single sign-on"
  oidc_discovery_url            = var.oidc_discovery_url
  oidc_client_id                = var.oidc_client_id
  oidc_client_secret_wo         = var.oidc_client_secret
  oidc_client_secret_wo_version = var.oidc_client_secret_version
  default_role                  = var.oidc_admin_role_name

  tune {
    listing_visibility = "unauth"
    default_lease_ttl  = "15m"
    max_lease_ttl      = "1h"
    token_type         = "default-service"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "vault_jwt_auth_backend_role" "admin" {
  count                  = var.oidc_enabled ? 1 : 0
  backend                = vault_jwt_auth_backend.oidc[0].path
  role_name              = var.oidc_admin_role_name
  role_type              = "oidc"
  user_claim             = "sub"
  groups_claim           = "groups"
  oidc_scopes            = ["profile", "email", "groups"]
  bound_audiences        = [var.oidc_client_id]
  bound_claims_type      = "string"
  bound_claims           = { groups = var.oidc_admin_group }
  allowed_redirect_uris  = local.oidc_redirect_uris
  token_policies         = []
  token_ttl              = 900
  token_max_ttl          = 3600
  token_explicit_max_ttl = 3600
  token_type             = "service"
  verbose_oidc_logging   = false
}

# Privileged access requires both the bound claim and this external group alias.
resource "vault_identity_group" "admins" {
  count    = var.oidc_enabled ? 1 : 0
  name     = var.oidc_admin_group
  type     = "external"
  policies = [vault_policy.admin.name]
}

resource "vault_identity_group_alias" "admins" {
  count          = var.oidc_enabled ? 1 : 0
  name           = var.oidc_admin_group
  mount_accessor = vault_jwt_auth_backend.oidc[0].accessor
  canonical_id   = vault_identity_group.admins[0].id
}

resource "vault_policy" "admin" {
  name   = var.oidc_admin_policy_name
  policy = file("${path.module}/policies/admin.hcl")
}
