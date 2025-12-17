# idp/keycloak-config

Declarative Keycloak configuration: realms, roles, and OpenID Connect clients. Intended to be invoked after Keycloak is installed (see `k8s/keycloak-helm`).

```hcl
module "keycloak_realms" {
  source = "../../modules/idp/keycloak-config"

  realms = {
    platform = {
      display_name = "Platform SSO"
      roles = {
        "platform.admin" = {}
      }
      clients = {
        "argocd" = {
          client_id     = "argocd"
          redirect_uris = ["https://argocd.apps.example.com/auth/callback"]
          web_origins   = ["https://argocd.apps.example.com"]
          client_secret = var.argocd_client_secret
        }
      }
    }
  }
}
```
