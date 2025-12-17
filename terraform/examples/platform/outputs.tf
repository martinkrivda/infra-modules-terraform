output "k3s_server_ip" {
  value       = module.k3s_server.ip_address
  description = "Control plane VM IP."
}

output "k3s_worker_ip" {
  value       = module.k3s_worker.ip_address
  description = "Worker VM IP."
}
