terraform {
  required_version = ">= 1.5.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.34.0"
    }
  }
}

locals {
  tags = distinct(compact(concat(var.tags, [for k, v in var.labels : format("%s:%s", k, v)])))
}

resource "digitalocean_droplet" "this" {
  name       = var.name
  region     = var.region
  size       = var.size
  image      = var.image
  backups    = var.enable_backups
  monitoring = var.monitoring
  ipv6       = var.enable_ipv6
  vpc_uuid   = var.vpc_uuid
  ssh_keys   = var.ssh_keys
  user_data  = var.user_data
  tags       = local.tags
}
