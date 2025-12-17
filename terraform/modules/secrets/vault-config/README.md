# secrets/vault-config

Configures Vault mounts, policies, and optional bootstrap secrets. Use it after deploying Vault via Helm.

```hcl
module "vault_config" {
  source = "../../modules/secrets/vault-config"

  kv_engines = [
    {
      path        = "apps"
      description = "Application secrets"
    }
  ]

  policies = {
    "platform-admin" = <<-EOP
      path "apps/*" {
        capabilities = ["list", "read", "update"]
      }
    EOP
  }
}
```
