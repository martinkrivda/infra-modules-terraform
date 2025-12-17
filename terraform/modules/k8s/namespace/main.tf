terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.26.0"
    }
  }
}

locals {
  labels = merge({
    "platform.martin.dev/environment" = var.environment,
    "platform.martin.dev/component"   = var.component,
  }, var.labels)
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name        = var.name
    labels      = local.labels
    annotations = var.annotations
  }
}

resource "kubernetes_resource_quota_v1" "this" {
  for_each = var.resource_quota == null ? {} : { quota = var.resource_quota }

  metadata {
    name      = "${var.name}-quota"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }

  spec {
    hard = each.value
  }
}

resource "kubernetes_limit_range_v1" "this" {
  for_each = var.limit_range == null ? {} : { limits = var.limit_range }

  metadata {
    name      = "${var.name}-limits"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = each.value.default_cpu
        memory = each.value.default_memory
      }
      default_request = {
        cpu    = each.value.request_cpu
        memory = each.value.request_memory
      }
    }
  }
}
