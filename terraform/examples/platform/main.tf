terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 3.0.2-rc07"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.28.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.34.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.26.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = ">= 4.4.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 3.21.0"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox.api_url
  pm_api_token_id     = var.proxmox.api_token_id
  pm_api_token_secret = var.proxmox.api_token_secret
  pm_tls_insecure     = var.proxmox.insecure
}

provider "cloudflare" {
  api_token = var.cloudflare.api_token
}

provider "digitalocean" {
  token = var.digitalocean.token
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
}

provider "kubectl" {
  config_path = var.kubeconfig_path
}

provider "keycloak" {
  url           = var.keycloak.url
  realm         = var.keycloak.realm
  client_id     = var.keycloak.client_id
  client_secret = var.keycloak.client_secret
}

provider "vault" {
  address = var.vault.address
  token   = var.vault.token
}

module "k3s_server" {
  source = "../../modules/compute/proxmox-vm-debian"

  name        = var.k3s_server.name
  environment = var.environment
  role        = "k3s-control-plane"
  target_node = var.k3s_server.target_node
  template    = var.proxmox_template

  cpu       = var.k3s_server.cpu
  memory_mb = var.k3s_server.memory_mb
  disks     = var.k3s_server.disks
  network   = var.k3s_server.network

  cloud_init = var.cloud_init
  tags       = ["k3s", "control-plane"]
}

module "k3s_worker" {
  source = "../../modules/compute/proxmox-vm-debian"

  name        = var.k3s_worker.name
  environment = var.environment
  role        = "k3s-worker"
  target_node = var.k3s_worker.target_node
  template    = var.proxmox_template

  cpu       = var.k3s_worker.cpu
  memory_mb = var.k3s_worker.memory_mb
  disks     = var.k3s_worker.disks
  network   = var.k3s_worker.network

  cloud_init = var.cloud_init
  tags       = ["k3s", "worker"]
}

module "cloudflare_records" {
  source = "../../modules/dns/cloudflare-records"

  zone_id = var.cloudflare.zone_id
  records = var.cloudflare_records
}

module "argocd" {
  source = "../../modules/k8s/argocd-helm"

  values = {
    configs = {
      params = {
        "server.insecure" = true
      }
    }
  }

  bootstrap_projects     = var.argocd_projects
  bootstrap_applications = var.argocd_apps
}

module "platform_namespace" {
  source = "../../modules/k8s/namespace"

  name        = "platform"
  environment = var.environment
  component   = "platform"
}

module "keycloak" {
  source = "../../modules/k8s/keycloak-helm"

  external_database = var.keycloak_db
  admin             = var.keycloak_admin
  ingress           = var.keycloak_ingress
}

module "vault" {
  source = "../../modules/k8s/vault-helm"

  ingress      = var.vault_ingress
  extra_values = var.vault_extra_values
}

module "bootstrap" {
  source = "../../modules/k8s/k3s-bootstrap"

  manifests = [
    {
      name    = "cloudflared-tunnel"
      content = <<-YAML
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: cloudflared
          namespace: kube-system
        spec:
          selector:
            matchLabels:
              app: cloudflared
          template:
            metadata:
              labels:
                app: cloudflared
            spec:
              containers:
                - name: cloudflared
                  image: cloudflare/cloudflared:latest
                  args: ["tunnel", "run"]
                  env:
                    - name: TUNNEL_TOKEN
                      valueFrom:
                        secretKeyRef:
                          name: cloudflared-token
                          key: token
      YAML
    }
  ]
}

module "keycloak_config" {
  source = "../../modules/idp/keycloak-config"

  realms = var.keycloak_realms
}

module "vault_config" {
  source = "../../modules/secrets/vault-config"

  kv_engines     = var.vault_kv_engines
  policies       = var.vault_policies
  static_secrets = []
}
