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

## New single-realm SSO configurations

Use [`idp/keycloak-realm`](../keycloak-realm) for new interactive SSO deployments.
It uses the maintained keycloak/keycloak provider and strict callbacks, grants,
group claims and realm security. This legacy multi-realm interface and its
resource addresses remain unchanged; migration requires explicit state mapping.
