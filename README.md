# infra-modules-terraform

Reusable Terraform modules for building a minimalist self-hosted platform on top of Proxmox + k3s. The repository acts as a shared catalog of building blocks: it contains only module code, input descriptions, validations, outputs, and documentation – never per-environment values or secrets.

## Why this exists

- **Minimalist platform** – One k3s control-plane VM and one worker VM on Proxmox host everything: GitOps workloads, data services, build jobs, and supporting tooling (Keycloak, Argo CD, Coolify, etc.).
- **Cloudflare first** – Public ingress happens via Cloudflare Tunnel, which feeds Traefik inside the cluster. No public IP or port-forwarding required.
- **Split provisioning** – Coolify deploys user-facing apps (PHP, Next.js). Argo CD handles internal services (APIs, Umami, Uptime Kuma, Keycloak, MariaDB, PostgreSQL, Redis).
- **Security + identity** – Keycloak exposes SSO for internal tooling and optionally for workloads. Vault + secrets modules shape secure storage patterns.
- **Future friendly** – Modules are opinionated yet parameterized, so you can start tiny and scale / swap providers later without rewriting everything.

## Repository layout

```
terraform/
  modules/
    compute/         # Proxmox & DigitalOcean compute blueprints
    db/              # MariaDB / MySQL database modules
    dns/             # Cloudflare DNS record orchestration
    k8s/             # Helm / Kubernetes resources (Argo CD, Vault, Keycloak, namespaces, bootstrap)
    idp/             # Identity provider configuration (Keycloak realms/clients)
    secrets/         # Vault structure, policies, engines
  examples/          # Opinionated end-to-end compositions (k3s on Proxmox, Cloudflare, etc.)
```

Supporting files in the repo root (`Makefile`, `.tflint.hcl`, `.pre-commit-config.yaml`, `.editorconfig`, `.gitattributes`) codify infrastructure-as-code best practices.

## Module catalog

| Domain   | Module | Description |
|----------|--------|-------------|
| Compute  | `compute/proxmox-vm-debian` | Creates a Debian-based VM from a Proxmox template with cloud-init, disks, networking, and tagging conventions. |
|          | `compute/proxmox-lxc-service` | Builds k3s-friendly LXC containers for auxiliary services (registries, CI helpers, etc.). |
|          | `compute/do-droplet-debian` | Opinionated DigitalOcean Debian droplet for off-site workloads or worker expansion. |
| Database | `db/mariadb-app` | Creates MariaDB databases/users, grants, and stores credentials in Vault KV v2 (MySQL provider). |
|          | `db/postgres-app` | Creates PostgreSQL databases/users, grants, and stores credentials in Vault KV v2. |
| DNS      | `dns/cloudflare-records` | Manages individual records and record sets (A, AAAA, CNAME, TXT, wildcard) via Cloudflare. |
| K8s      | `k8s/namespace` | Creates consistent namespaces with labels/quotas. |
|          | `k8s/argocd-helm` | Installs Argo CD via Helm with bootstrap projects and repositories. |
|          | `k8s/keycloak-helm` | Deploys Keycloak (Helm) with PostgreSQL connection secrets + ingress for SSO. |
|          | `k8s/vault-helm` | Deploys HashiCorp Vault via Helm (HA optional, storage choice pluggable). |
|          | `k8s/k3s-bootstrap` | Applies base manifests/CRDs/operators after fresh k3s install (Traefik config, Cloudflare Tunnel DaemonSet, etc.). |
| Identity | `idp/keycloak-config` | Declares realms, clients, roles, and default users using the Keycloak Terraform provider. |
| Secrets  | `secrets/vault-config` | Sets Vault auth methods, policies, and secrets engines for apps + platform services. |

Each module includes its own README with usage, inputs, outputs, and examples.

## Quick start

1. **Install prerequisites** (see the list below).
2. Clone the repository and review module READMEs:
   ```bash
   git clone git@github.com:your-org/infra-modules-terraform.git
   cd infra-modules-terraform
   ```
3. Bootstrap tooling (optional but recommended):
   ```bash
   make tools   # install pre-commit hooks, run fmt + lint once
   pre-commit install
   ```
4. Copy and adapt an example composition:
   ```bash
   cp -r terraform/examples/platform my-env
   cd my-env
   terraform init && terraform plan
   ```
5. Reference the modules from your environment-specific repo. Pass only parameters (IPs, storage pools, secrets references) from that repo – keep this catalog generic.

## Prerequisites

- Terraform ≥ 1.6.x
- `tflint` ≥ 0.51 for static analysis
- `terraform-docs` ≥ 0.17 for README generation (optional but used by tooling)
- `pre-commit` with the `terraform` hook set
- `helm` ≥ 3.12 and `kubectl` ≥ 1.28 for interacting with the k3s cluster
- `cloudflared`, `argocd`, and `k3sup` CLIs if you follow the recommended bootstrap path
- Access credentials/tokens for Proxmox, DigitalOcean, Cloudflare, Keycloak, and Vault providers
- A workstation with SSH access to the Proxmox host (for image/template preparation)

## Tagging & metadata conventions

- Every module accepts `labels` (map) and/or `tags` (list). Minimum keys: `environment`, `component`, `owner`, `managed_by`, `repository`.
- Proxmox modules join labels into semicolon-separated tags for VM metadata.
- Kubernetes/Helm modules create Kubernetes labels/annotations so workloads and GitOps tooling stay traceable.
- DNS records automatically append `managed_by = terraform` and `source = infra-modules-terraform` unless overridden.

## Tooling & workflows

- `make fmt` / `make lint` / `make validate` standardize Terraform formatting, run TFLint, and execute lightweight validations (backend disabled) on example stacks.
- `make docs` runs `terraform-docs` for every module (matches README tables).
- `pre-commit run --all-files` ties everything together (fmt + docs + tflint + yaml).
- `.tflint.hcl` configures core rules plus Terraform best-practice plugins.
- `.gitattributes` enforces LF endings and Terraform-aware diffs.

## Authoring guidelines

- Modules stay generic. No production values, `*.tfvars`, or secrets are ever committed here.
- Each module exposes a `README.md`, `variables.tf`, and `outputs.tf` with descriptions + validations.
- Use locals for shared logic, keep interfaces coarse-grained (e.g., `network_interfaces`, `storage_disks`, `ingress`, `helm_values`).
- Prefer composable outputs (IDs, IPs, kube context) over entire resources.
- Follow semantic versioning when tagging releases; treat the repo like a provider catalog.

## Architecture reference

1. **Infra base** – Proxmox hosts `k3s-server` (control-plane only) + `k3s-worker` (all workloads & builds). It optionally adds DigitalOcean droplet workers during bursts.
2. **Ingress** – Cloudflare Tunnel (DaemonSet in k3s) terminates TLS on Cloudflare, forwards to Traefik. Traefik routes traffic to services via hostname/path rules.
3. **Deploy pipelines** – Coolify handles developer-friendly app deploys, Argo CD enforces GitOps for critical/internal services.
4. **Data services** – MariaDB (apps), PostgreSQL (Keycloak), Redis (cache). Vault manages secrets engines/policies, Keycloak offers SSO.
5. **Observability** – Modules encourage adding Umami + Uptime Kuma via Argo CD projects with sealed secrets / Vault injectors.

Use this repository as the foundation. Create per-environment repos that pin module versions, pass actual values, and supply backend configuration.
