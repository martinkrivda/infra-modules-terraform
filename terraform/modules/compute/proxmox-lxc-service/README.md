# compute/proxmox-lxc-service

Builds a lightweight Debian-based LXC container on Proxmox for workloads that do not need a full VM (artifact registries, backup helpers, lightweight services). The module standardizes CPU/memory/rootfs/network inputs and exposes simple outputs for DNS or monitoring wiring.

```hcl
module "registry" {
  source = "../../modules/compute/proxmox-lxc-service"

  service_name = "docker-registry"
  environment  = "lab"
  target_node  = "pve01"
  template     = "local:vztmpl/debian-12-default_20240303_amd64.tar.zst"

  network = {
    bridge       = "vmbr0"
    ipv4_cidr    = "10.42.0.30/24"
    gateway_ipv4 = "10.42.0.1"
  }

  credentials = {
    password        = "super-secret"
    ssh_public_keys = [file("~/.ssh/id_ed25519.pub")]
  }

  tags = ["service", "registry"]
}
```
