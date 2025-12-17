terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

locals {
  manifest_map = { for manifest in var.manifests : manifest.name => manifest }
}

resource "kubectl_manifest" "bootstrap" {
  for_each = local.manifest_map

  yaml_body = each.value.content
}
