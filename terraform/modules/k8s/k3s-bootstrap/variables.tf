variable "manifests" {
  description = "List of raw Kubernetes manifests (YAML) applied as part of the bootstrap (CRDs, base config, Traefik patches, cloudflared, etc.)."
  type = list(object({
    name    = string
    content = string
  }))
  default = []
}
