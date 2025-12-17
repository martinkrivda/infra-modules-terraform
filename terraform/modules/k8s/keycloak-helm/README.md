# k8s/keycloak-helm

Deploys Keycloak via the Bitnami chart, wired to an external PostgreSQL database and optional ingress managed by Traefik/Cloudflare Tunnel.

```hcl
module "keycloak" {
  source = "../../modules/k8s/keycloak-helm"

  external_database = {
    host                 = "mariadb.platform.svc.cluster.local"
    port                 = 5432
    database             = "keycloak"
    user                 = "kc"
    password_secret_name = "keycloak-db"
    password_secret_key  = "password"
  }

  admin = {
    user        = "admin"
    secret_name = "keycloak-admin"
    secret_key  = "password"
  }

  ingress = {
    enabled         = true
    hostname        = "sso.apps.example.com"
    tls_secret_name = "keycloak-tls"
    annotations     = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "websecure"
    }
  }
}
```
