resource "vault_mount" "kv" {
  for_each    = var.kv_mounts
  path        = each.key
  type        = "kv"
  description = each.value.description
  options     = { version = "2" }

  lifecycle {
    prevent_destroy = true
  }
}

resource "vault_kv_secret_backend_v2" "kv" {
  for_each     = vault_mount.kv
  mount        = each.value.path
  max_versions = var.kv_mounts[each.key].max_versions
  # Existing filler clients do not always send CAS. Enable mandatory CAS only
  # after migrating every writer; individual writers may use CAS already.
  cas_required         = var.kv_mounts[each.key].cas_required
  delete_version_after = var.kv_mounts[each.key].delete_version_after
}
