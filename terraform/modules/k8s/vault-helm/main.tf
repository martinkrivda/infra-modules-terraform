terraform {
  required_version = ">= 1.5.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.1"
    }
  }
}

locals {
  base_values = {
    server = {
      ha = {
        enabled = var.ha_enabled
      }
      dataStorage = {
        size         = var.raft_storage_size
        storageClass = var.raft_storage_class
      }
      auditStorage = {
        enabled = true
        size    = "5Gi"
      }
      ingress = {
        enabled     = var.ingress.enabled
        annotations = var.ingress.annotations
        hosts = [
          {
            host  = var.ingress.hostname
            paths = [{ path = "/", pathType = "Prefix" }]
          }
        ]
        tls = [
          {
            hosts      = [var.ingress.hostname]
            secretName = var.ingress.tls_secret_name
          }
        ]
      }
    }
    injector = {
      enabled = var.injector_enabled
    }
  }

  merged_values = merge(local.base_values, var.extra_values)
}

resource "helm_release" "vault" {
  name       = var.release_name
  repository = var.repository
  chart      = var.chart
  version    = var.chart_version
  namespace  = var.namespace

  create_namespace = true
  values           = [yamlencode(local.merged_values)]
}
