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
  pool        = "lab-platform"

  cpu = {
    sockets = 1
    cores   = 2
    model   = "host"
  }

  memory_mb = 4096

  disks = [{
    type    = "scsi"
    storage = "vm-data"
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

### Convenience overrides

The module keeps the original `cpu`, `memory_mb`, `disks`, `network`, and `cloud_init` inputs for backward compatibility while exposing optional knobs for common day-to-day tweaks. Use any combination of the following to configure pool membership, template VMID, SSH keys, networking, and storage layouts without redefining the full structures:

```hcl
module "k3s_server" {
  # ...
  pool          = "lab-platform"
  template_vmid = 9000

  ssh_public_keys = [file("~/.ssh/id_ed25519.pub")]

  ipv4_address       = "10.42.0.10"
  ipv4_prefix_length = 24
  ipv4_gateway       = "10.42.0.1"

  cpu_cores          = 4
  cpu_sockets        = 1
  memory_override_mb = 6144

  os_disk = {
    storage = "vm-data"
    size_gb = 60
  }

  data_disks = [{
    storage = "vm-data"
    size_gb = 150
    slot    = 1
  }]
}
```

Review `variables.tf` for the full set of inputs.
