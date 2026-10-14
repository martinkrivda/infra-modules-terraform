terraform {
  required_version = ">= 1.11.0, < 2.0.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.9.0, < 6.0.0"
    }
  }
}

provider "vault" {
  address = var.vault_address
  # Supply administrator credentials through VAULT_TOKEN or Vault CLI login.
}

variable "vault_address" {
  description = "Public HTTPS origin of an initialized and unsealed Vault."
  type        = string
}

module "vault" {
  source = "../../modules/secrets/vault-platform"

  vault_address = var.vault_address
  kv_mounts = {
    platform = { description = "Platform secrets" }
  }
  kubernetes_roles = {
    external-secrets = {
      service_account = "external-secrets"
      namespace       = "external-secrets"
      read_paths      = ["platform/data/services/database"]
    }
  }
}
