# Only the explicitly bound Keycloak vault-admins group receives this policy.
path "*" {
  capabilities = ["create", "read", "update", "patch", "delete", "list", "sudo"]
}
