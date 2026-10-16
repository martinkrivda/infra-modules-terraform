terraform {
  required_version = ">= 1.7.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "= 5.14.0"
    }
  }
}

# Supply CLOUDFLARE_API_TOKEN in the environment. This example creates nothing
# until the consumer explicitly supplies maps and imports existing objects.
provider "cloudflare" {}

variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
}

module "dns" {
  source     = "../../modules/dns/cloudflare-zones"
  account_id = var.account_id
}

module "zero_trust" {
  source     = "../../modules/network/cloudflare-zero-trust"
  account_id = var.account_id
}
