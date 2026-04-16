# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A shared catalog of reusable Terraform modules for a minimalist self-hosted platform (Proxmox + k3s). It contains only module code, variables, validations, outputs, and documentation — never per-environment values, `*.tfvars`, or secrets. Environment-specific repos reference these modules by version.

## Commands

```bash
make fmt        # terraform fmt -recursive across the whole tree
make lint       # tflint --recursive
make validate   # init -backend=false + validate on terraform/examples/platform
make docs       # terraform-docs for every module
make tools      # fmt + lint + validate in sequence
make clean      # remove all .terraform/ caches

pre-commit install              # install hooks once
pre-commit run --all-files      # run all hooks (fmt, validate, tflint, docs, trivy, yaml)
```

Individual module validation (no backend required):
```bash
terraform -chdir=terraform/modules/<domain>/<module> init -backend=false
terraform -chdir=terraform/modules/<domain>/<module> validate
```

## Architecture

### Module domains

| Domain | Path | Providers |
|--------|------|-----------|
| Compute | `terraform/modules/compute/` | Telmate/proxmox, digitalocean |
| Database | `terraform/modules/db/` | mysql (MariaDB), postgresql, vault |
| DNS | `terraform/modules/dns/` | cloudflare |
| Kubernetes | `terraform/modules/k8s/` | kubernetes, helm, kubectl |
| Identity | `terraform/modules/idp/` | mrparkers/keycloak |
| Secrets | `terraform/modules/secrets/` | hashicorp/vault |

### Vault secret path convention

DB modules store credentials under a Vault KV v2 mount (default `apps`):
- App user: `<vault_mount>/<app_group>/<environment>/<app_name>/databases/mariadb` (or `.../postgres`)
- Admin users: `<vault_mount>/<app_group>/<environment>/admins/mariadb/<username>`

The path prefixes are overridable via `vault_app_secret_prefix` / `vault_admin_secret_prefix`.

### Tagging/labeling convention

Every module accepts `labels` (map) and/or `tags` (list). Required minimum keys: `environment`, `component`, `owner`, `managed_by`, `repository`.
- Proxmox: labels are joined as semicolon-separated VM tags.
- k8s/Helm: labels become Kubernetes labels/annotations.
- DNS: `managed_by = terraform` and `source = infra-modules-terraform` are appended automatically.

### Example composition

`terraform/examples/platform/` wires all modules together with every provider. It is also the target used by `make validate`. Use it as reference when building new integrations.

## Authoring rules

- All resource/variable/local names must use `snake_case` (enforced by TFLint `terraform_naming_convention`).
- Every module must declare `required_version` (≥ 1.6.x) and `required_providers` with explicit version constraints (TFLint `terraform_required_providers`, `terraform_required_version`).
- Each module must have `variables.tf` with `description` and `type` on every variable, `outputs.tf` with `description` on every output, and a `README.md` kept current by `terraform-docs`.
- Use `locals` for shared logic; keep input interfaces coarse-grained (e.g. objects for `network_interfaces`, `storage_disks`, `ingress`).
- Prefer outputting IDs/IPs/contexts over full resource objects.
- Passwords that are `null`/empty are auto-generated via `random_password`; never hard-code credentials.
- `terraform_trivy` runs at `HIGH,CRITICAL` severity — new resources must pass this check before commit.
