# k8s/argocd-helm

Installs Argo CD via Helm and optionally bootstraps AppProjects + Applications using CR manifests applied through the `kubectl` provider.

```hcl
module "argocd" {
  source = "../../modules/k8s/argocd-helm"

  namespace = "argocd"
  values = {
    configs = {
      params = {
        "server.insecure" = true
      }
    }
  }

  bootstrap_projects = [{
    name                = "platform"
    source_repositories = ["https://github.com/your-org/platform-gitops.git"]
    destinations = [{
      namespace = "*"
      server    = "https://kubernetes.default.svc"
    }]
  }]
}
```
