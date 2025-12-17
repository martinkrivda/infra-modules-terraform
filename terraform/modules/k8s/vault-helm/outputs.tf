output "namespace" {
  description = "Namespace where Vault is deployed."
  value       = var.namespace
}

output "hostname" {
  description = "Ingress hostname for Vault."
  value       = var.ingress.hostname
}
