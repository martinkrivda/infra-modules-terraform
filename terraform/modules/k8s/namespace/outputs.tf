output "name" {
  description = "Namespace name."
  value       = kubernetes_namespace_v1.this.metadata[0].name
}

output "labels" {
  description = "Effective labels applied to the namespace."
  value       = local.labels
}
