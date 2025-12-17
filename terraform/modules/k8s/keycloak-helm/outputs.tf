output "namespace" {
  description = "Namespace for Keycloak release."
  value       = var.namespace
}

output "hostname" {
  description = "Hostname used by the ingress."
  value       = var.ingress.hostname
}
