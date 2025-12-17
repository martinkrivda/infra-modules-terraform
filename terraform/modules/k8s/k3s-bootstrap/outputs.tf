output "applied_manifests" {
  description = "Names of bootstrap manifests applied to the cluster."
  value       = keys(local.manifest_map)
}
