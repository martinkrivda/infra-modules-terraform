terraform {
  required_version = ">= 1.5.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.6.0"
    }
  }
}

locals {
  kv_mounts = {
    for engine in var.kv_engines : engine.path => engine
  }

  static_secrets = {
    for secret in var.static_secrets : secret.path => secret
  }
}

resource "vault_mount" "kv" {
  for_each = local.kv_mounts

  path        = each.value.path
  type        = each.value.type
  description = each.value.description
  options     = each.value.options
}

resource "vault_policy" "policies" {
  for_each = var.policies

  name   = each.key
  policy = each.value
}

resource "vault_kv_secret_v2" "static" {
  for_each = local.static_secrets

  mount               = each.value.mount
  name                = each.value.path
  data_json           = jsonencode(each.value.data)
  delete_all_versions = false

  depends_on = [vault_mount.kv]
}
