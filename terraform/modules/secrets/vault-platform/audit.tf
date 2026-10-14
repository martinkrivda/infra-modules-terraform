resource "vault_audit" "stdout" {
  type        = "file"
  path        = "stdout"
  description = "JSON audit events for the Kubernetes log collector"
  options = {
    file_path     = "stdout"
    log_raw       = "false"
    hmac_accessor = "true"
  }

  lifecycle {
    prevent_destroy = true
  }
}
