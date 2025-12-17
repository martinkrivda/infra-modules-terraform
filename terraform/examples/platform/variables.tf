variable "environment" {
  description = "Environment name applied to modules."
  type        = string
  default     = "lab"
}

variable "proxmox" {
  description = "Proxmox API authentication parameters."
  type = object({
    api_url          = string
    api_token_id     = string
    api_token_secret = string
    insecure         = bool
  })
  default = {
    api_url          = "https://proxmox.example.local:8006/api2/json"
    api_token_id     = "terraform@pve!token"
    api_token_secret = "changeme"
    insecure         = true
  }
}

variable "proxmox_template" {
  description = "Cloud-init template name."
  type        = string
  default     = "debian-12-cloudinit"
}

variable "k3s_server" {
  type = object({
    name        = string
    target_node = string
    cpu         = object({ sockets = number, cores = number, model = string })
    memory_mb   = number
    disks       = list(object({ type = string, storage = string, size_gb = number, slot = number }))
    network = object({
      bridge       = string
      ipv4_cidr    = string
      gateway_ipv4 = string
      model        = optional(string)
      firewall     = optional(bool)
      vlan_tag     = optional(number)
      mtu          = optional(number)
    })
  })
  default = {
    name        = "k3s-server"
    target_node = "pve01"
    cpu = {
      sockets = 1
      cores   = 2
      model   = "host"
    }
    memory_mb = 4096
    disks = [{
      type    = "scsi"
      storage = "local-lvm"
      size_gb = 40
      slot    = 0
    }]
    network = {
      bridge       = "vmbr0"
      ipv4_cidr    = "10.42.0.10/24"
      gateway_ipv4 = "10.42.0.1"
    }
  }
}

variable "k3s_worker" {
  type = object({
    name        = string
    target_node = string
    cpu         = object({ sockets = number, cores = number, model = string })
    memory_mb   = number
    disks       = list(object({ type = string, storage = string, size_gb = number, slot = number }))
    network = object({
      bridge       = string
      ipv4_cidr    = string
      gateway_ipv4 = string
      model        = optional(string)
      firewall     = optional(bool)
      vlan_tag     = optional(number)
      mtu          = optional(number)
    })
  })
  default = {
    name        = "k3s-worker"
    target_node = "pve01"
    cpu = {
      sockets = 1
      cores   = 4
      model   = "host"
    }
    memory_mb = 8192
    disks = [{
      type    = "scsi"
      storage = "local-lvm"
      size_gb = 80
      slot    = 0
    }]
    network = {
      bridge       = "vmbr0"
      ipv4_cidr    = "10.42.0.11/24"
      gateway_ipv4 = "10.42.0.1"
    }
  }
}

variable "cloud_init" {
  description = "Cloud-init defaults for Proxmox VMs."
  type = object({
    user            = string
    password        = string
    ssh_public_keys = list(string)
  })
  default = {
    user            = "debian"
    password        = "super-secret"
    ssh_public_keys = ["ssh-ed25519 AAA..."]
  }
}

variable "cloudflare" {
  description = "Cloudflare authentication + zone metadata."
  type = object({
    api_token = string
    zone_id   = string
  })
  default = {
    api_token = "cf_token"
    zone_id   = "zone-id"
  }
}

variable "cloudflare_records" {
  description = "Records managed by the example stack."
  type = list(object({
    name    = string
    type    = string
    value   = optional(string)
    values  = optional(list(string))
    ttl     = optional(number)
    proxied = optional(bool)
  }))
  default = [
    {
      name    = "apps"
      type    = "CNAME"
      value   = "tunnel.example.com"
      proxied = true
    }
  ]
}

variable "argocd_projects" {
  description = "Seed Argo CD projects."
  type = list(object({
    name                       = string
    source_repositories        = list(string)
    destinations               = list(object({ namespace = string, server = string }))
    annotations                = optional(map(string))
    description                = optional(string)
    cluster_resource_whitelist = optional(list(object({ group = string, kind = string })), [])
  }))
  default = []
}

variable "argocd_apps" {
  description = "Seed Argo CD applications."
  type = list(object({
    name                  = string
    project               = string
    repo_url              = string
    path                  = string
    revision              = string
    destination_namespace = string
    destination_server    = string
    helm = optional(object({
      value_files = list(string)
    }))
    sync_policy = object({
      automated = bool
      prune     = bool
      self_heal = bool
      options   = optional(list(string), [])
    })
  }))
  default = []
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig for the freshly bootstrapped cluster."
  type        = string
  default     = "~/.kube/config"
}

variable "keycloak" {
  description = "Keycloak provider authentication."
  type = object({
    url           = string
    realm         = string
    client_id     = string
    client_secret = string
  })
  default = {
    url           = "https://sso.apps.example.com"
    realm         = "master"
    client_id     = "terraform"
    client_secret = "secret"
  }
}

variable "keycloak_db" {
  description = "External DB values for Keycloak Helm module."
  type = object({
    host                 = string
    port                 = number
    database             = string
    user                 = string
    password_secret_name = string
    password_secret_key  = string
  })
  default = {
    host                 = "postgres.platform.svc.cluster.local"
    port                 = 5432
    database             = "keycloak"
    user                 = "keycloak"
    password_secret_name = "keycloak-db"
    password_secret_key  = "password"
  }
}

variable "keycloak_admin" {
  description = "Admin secret metadata."
  type = object({
    user        = string
    secret_name = string
    secret_key  = string
  })
  default = {
    user        = "admin"
    secret_name = "keycloak-admin"
    secret_key  = "password"
  }
}

variable "keycloak_ingress" {
  description = "Ingress configuration for Keycloak Helm module."
  type = object({
    enabled         = bool
    hostname        = string
    tls_secret_name = string
    annotations     = map(string)
  })
  default = {
    enabled         = true
    hostname        = "sso.apps.example.com"
    tls_secret_name = "keycloak-tls"
    annotations     = {}
  }
}

variable "keycloak_realms" {
  description = "Realms/clients managed by the Keycloak config module."
  type        = map(any)
  default     = {}
}

variable "vault" {
  description = "Vault provider authentication."
  type = object({
    address = string
    token   = string
  })
  default = {
    address = "https://vault.apps.example.com"
    token   = "root"
  }
}

variable "vault_ingress" {
  description = "Ingress configuration for Vault Helm module."
  type = object({
    enabled         = bool
    hostname        = string
    tls_secret_name = string
    annotations     = map(string)
  })
  default = {
    enabled         = true
    hostname        = "vault.apps.example.com"
    tls_secret_name = "vault-tls"
    annotations     = {}
  }
}

variable "vault_extra_values" {
  description = "Optional overrides for Vault Helm chart."
  type        = map(any)
  default     = {}
}

variable "vault_kv_engines" {
  description = "KV engines to create inside Vault."
  type        = list(any)
  default     = []
}

variable "vault_policies" {
  description = "Policies fed to vault-config module."
  type        = map(string)
  default     = {}
}
