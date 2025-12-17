resource "helm_release" "vault" {
  name       = "vault"
  namespace  = var.namespace

  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = var.chart_version

  create_namespace = false

  values = [
    var.values_yaml
  ]
}
