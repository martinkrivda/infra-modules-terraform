output "namespace" {
  description = "Namespace where Argo CD is installed."
  value       = var.namespace
}

output "release_name" {
  description = "Name of the Helm release."
  value       = helm_release.argocd.name
}
