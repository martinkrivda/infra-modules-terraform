# compute/do-droplet-debian

Creates a Debian droplet on DigitalOcean for burst capacity or remote workers. Droplets can join the k3s cluster, serve as build boxes, or host ancillary services.

```hcl
module "runner" {
  source = "../../modules/compute/do-droplet-debian"

  name    = "k3s-worker-do"
  region  = "fra1"
  size    = "s-2vcpu-4gb"
  ssh_keys = [data.digitalocean_ssh_key.martin.id]

  labels = {
    environment = "lab"
    component   = "k3s-worker"
  }
}
```
