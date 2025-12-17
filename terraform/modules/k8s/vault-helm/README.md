# k8s/vault-helm

Deploys HashiCorp Vault via Helm with HA/Raft defaults and ingress ready to sit behind Cloudflare Tunnel + Traefik.

```hcl
module "vault" {
  source = "../../modules/k8s/vault-helm"

  ingress = {
    enabled         = true
    hostname        = "vault.internal.example.com"
    tls_secret_name = "vault-tls"
    annotations     = {
      "traefik.ingress.kubernetes.io/router.middlewares" = "platform-auth@kubernetescrd"
    }
  }

  extra_values = {
    server = {
      standalone = {
        enabled = false
      }
    }
  }
}
```
