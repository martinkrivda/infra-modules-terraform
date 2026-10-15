terraform {
  required_version = ">= 1.7.0, < 2.0.0"
  required_providers {
    keycloak = { source = "keycloak/keycloak", version = "~> 5.7.0" }
  }
}
# Supply an authorized provider configuration from your environment.
module "keycloak" {
  source             = "../../modules/idp/keycloak-realm"
  realm_name         = "example"
  realm_display_name = "Example SSO"
  groups             = ["vault-app-prod-managers", "argocd-app-prod-deployers"]
  clients            = [{ client_id = "argocd", valid_redirect_uris = ["https://argocd.example.com/auth/callback"] }]
}
