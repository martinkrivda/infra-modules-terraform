terraform {
  required_version = ">= 1.11.0, < 2.0.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.9.0, < 6.0.0"
    }
  }
}
