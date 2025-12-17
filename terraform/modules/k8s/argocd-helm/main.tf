terraform {
  required_version = ">= 1.5.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.26.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

locals {
  helm_values = var.values == null ? [] : [yamlencode(var.values)]

  projects = {
    for project in var.bootstrap_projects : project.name => {
      name                       = project.name
      annotations                = coalesce(project.annotations, {})
      description                = coalesce(project.description, "")
      source_repositories        = project.source_repositories
      destinations               = project.destinations
      cluster_resource_whitelist = length(project.cluster_resource_whitelist) > 0 ? project.cluster_resource_whitelist : [{ group = "*", kind = "*" }]
    }
  }

  applications = {
    for app in var.bootstrap_applications : app.name => app
  }
}

resource "helm_release" "argocd" {
  name       = var.release_name
  repository = var.repository
  chart      = var.chart
  version    = var.chart_version
  namespace  = var.namespace

  create_namespace  = true
  atomic            = true
  dependency_update = true
  timeout           = 600

  values = local.helm_values
}

resource "kubectl_manifest" "projects" {
  for_each = local.projects

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name        = each.value.name
      namespace   = var.namespace
      annotations = merge({ "platform.martin.dev/managed-by" = "terraform" }, each.value.annotations)
    }
    spec = {
      description              = each.value.description
      sourceRepos              = each.value.source_repositories
      destinations             = [for destination in each.value.destinations : { namespace = destination.namespace, server = destination.server }]
      clusterResourceWhitelist = each.value.cluster_resource_whitelist
    }
  })

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "applications" {
  for_each = local.applications

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = each.value.name
      namespace  = var.namespace
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = each.value.project
      destination = {
        namespace = each.value.destination_namespace
        server    = each.value.destination_server
      }
      source = merge({
        repoURL        = each.value.repo_url
        path           = each.value.path
        targetRevision = each.value.revision
        }, each.value.helm == null ? {} : {
        helm = {
          valueFiles = each.value.helm.value_files
        }
      })
      syncPolicy = merge({
        syncOptions = each.value.sync_policy.options
        }, each.value.sync_policy.automated ? {
        automated = {
          prune    = each.value.sync_policy.prune
          selfHeal = each.value.sync_policy.self_heal
        }
      } : {})
    }
  })

  depends_on = [helm_release.argocd]
}
