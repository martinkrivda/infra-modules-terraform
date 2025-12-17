# compute/proxmox-vm-debian

Creates a Debian-based VM in Proxmox from an existing cloud-init template. The module standardizes CPU/memory/disk/network inputs, tags VMs with the shared metadata map, and emits VM identifiers for downstream modules (k3s bootstrap, Cloudflare DNS, etc.).

## Usage

```hcl
module "k3s_server" {
  source = "../../modules/compute/proxmox-vm-debian"

  name        = "k3s-server"
  environment = "lab"
  role        = "k3s-control-plane"
  target_node = "pve01"
  template    = "debian-12-cloudinit"

  cpu = {
    sockets = 1
    cores   = 2
    model   = "host"
  }

  memory_mb = 4096

  disks = [{
    type    = "scsi"
    storage = "nvme"
    size_gb = 40
    slot    = 0
  }]

  network = {
    bridge       = "vmbr0"
    ipv4_cidr    = "10.42.0.10/24"
    gateway_ipv4 = "10.42.0.1"
  }

  cloud_init = {
    user            = "debian"
    password        = "super-secret"
    ssh_public_keys = [file("~/.ssh/id_ed25519.pub")]
  }

  tags = ["k3s", "control-plane"]
}
```

Review `variables.tf` for the full set of inputs.
