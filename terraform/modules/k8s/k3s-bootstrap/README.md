# k8s/k3s-bootstrap

Applies a list of raw manifests after a fresh k3s install. Typical payload includes:

- CRDs for Argo CD, cert-manager, or other operators
- Traefik config patches
- Cloudflared Tunnel DaemonSet + credentials secret
- Base ConfigMaps/Secrets required by GitOps

```hcl
module "bootstrap" {
  source = "../../modules/k8s/k3s-bootstrap"

  manifests = [
    {
      name    = "cloudflared"
      content = file("manifests/cloudflared.yaml")
    }
  ]
}
```
