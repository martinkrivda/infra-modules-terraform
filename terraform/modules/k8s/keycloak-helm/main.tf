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
    replicaCount = var.replicas
    production   = true
    extraEnvVars = [for env in var.extra_env : {
      name  = env.name
      value = env.value
    }]
    ingress = {
      enabled     = var.ingress.enabled
      hostname    = var.ingress.hostname
      annotations = var.ingress.annotations
      tls = [
        {
          hosts      = [var.ingress.hostname]
          secretName = var.ingress.tls_secret_name
        }
      ]
    }
    externalDatabase = {
      host                      = var.external_database.host
      port                      = var.external_database.port
      database                  = var.external_database.database
      user                      = var.external_database.user
      existingSecret            = var.external_database.password_secret_name
      existingSecretPasswordKey = var.external_database.password_secret_key
    }
    auth = {
      adminUser         = var.admin.user
      existingSecret    = var.admin.secret_name
      passwordSecretKey = var.admin.secret_key
    }
  }

  merged_values = merge(local.base_values, var.extra_values)
}

resource "helm_release" "keycloak" {
  name       = var.release_name
  repository = var.repository
  chart      = var.chart
  version    = var.chart_version
  namespace  = var.namespace

  create_namespace = true
  values           = [yamlencode(local.merged_values)]
}
