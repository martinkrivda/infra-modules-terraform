resource "helm_release" "keycloak" {
  name       = "keycloak"
  namespace  = var.namespace

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "keycloak"
  version    = var.chart_version

  create_namespace = false

  values = [
    var.values_yaml
  ]
}
