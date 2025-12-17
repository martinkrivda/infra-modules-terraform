# k8s/namespace

Creates opinionated namespaces for the self-hosted platform with consistent labels, annotations, and optional quotas/limits.

```hcl
module "monitoring_ns" {
  source = "../../modules/k8s/namespace"

  name        = "monitoring"
  environment = "lab"
  component   = "observability"

  resource_quota = {
    pods           = "40"
    requests.cpu   = "8"
    requests.memory = "16Gi"
  }
}
```
