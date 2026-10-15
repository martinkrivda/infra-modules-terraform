terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "~> 5.7.0"
    }
  }
}
