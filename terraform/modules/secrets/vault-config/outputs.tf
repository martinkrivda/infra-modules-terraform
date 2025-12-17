output "mount_paths" {
  description = "Enabled KV mount paths."
  value       = [for mount in vault_mount.kv : mount.path]
}
