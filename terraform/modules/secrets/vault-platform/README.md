# secrets/vault-platform

Configure an existing Vault through its API: KV v2 mounts and retention,
Kubernetes auth and scoped read policies, optional OIDC administrator login,
and JSON audit to stdout. This module does not install Vault or populate values.
The existing `secrets/vault-config` module remains available unchanged.

Requires Terraform >= 1.11 and < 2, and Vault provider >= 5.9 and < 6.
Pass the provider from the root module; supply its credentials through the
environment or an existing Vault CLI login. Pin Git module sources to an
immutable commit or release.

See `terraform/examples/vault-platform` for a bootstrap composition.

## Authentication and ownership

Vault must run inside the target Kubernetes cluster with its projected service
account token and CA. Its service account needs TokenReview permission. The
module does not create Kubernetes RBAC. There is no static reviewer-token input.
Omitting reviewer JWT and CA uses Vault's rotating pod credentials for a new
configuration; it does not guarantee removal of a previously stored reviewer
JWT. Inspect an existing auth configuration before migration. This module is
not an external-Vault authentication recipe.

Workload roles bind one named account and namespace, grant only read on scoped
KV v2 paths, and optionally restrict JWT audience. An omitted audience retains
compatibility with the consumer's Kubernetes JWT. The default Vault policy
remains enabled for token self-service.

OIDC is disabled by default. Enabling it requires an HTTPS issuer and ephemeral
client secret. Full administrator access is granted through an exact `groups`
claim and matching external identity group, never directly through the login
role. The `sub` claim identifies the user. Redirects use the public Vault origin
and `http://localhost:8250/oidc/callback`. The provider write-only field keeps the
client secret out of state and saved plans; increment its version on rotation.

KV/auth mounts and the audit device have `prevent_destroy`. Existing data-bearing
mounts must be imported, not recreated. The module always creates its named
administrator policy and audit device, even when OIDC is disabled. Populate
secret values with a separate workflow so they do not enter Terraform state.

## Migration from the office-lab local module

Retain the caller name `module.vault`, resource keys, mount names, OIDC names
and `workload_policy_prefix = "k3s-"`. The resource addresses are intentionally
preserved, including `vault_kubernetes_auth_backend_config.k3s`. Pass environment
issuer and KV descriptions explicitly. Changing only the module source needs no
`moved` blocks or state replacement. Run `terraform init` after changing source,
then inspect the plan; metadata descriptions may change, but no managed object
should be destroyed or replaced. Use the original backend/state. A missing local
state is not evidence that the existing Vault is empty.

Run `terraform test` in this module for mocked bootstrap and authorization
checks. These tests do not prove actual Vault login or Kubernetes reachability.

## Inputs

| Input | Default | Purpose |
| --- | --- | --- |
| `vault_address` | Required | Public Vault HTTPS origin |
| `kv_mounts` | `{}` | KV v2 mounts, descriptions, retention, CAS |
| `kubernetes_host` | `https://kubernetes.default.svc:443` | API reachable from Vault |
| `kubernetes_auth_path` | `kubernetes` | Authentication mount |
| `kubernetes_roles` | `{}` | Account, namespace, read paths, optional audience |
| `workload_policy_prefix` | `k8s-` | Generated policy prefix |
| `oidc_enabled` | `false` | Enable identity provider login |
| `oidc_discovery_url` | `null` | HTTPS issuer, required when enabled |
| `oidc_client_id` | `vault` | Client ID and required audience |
| `oidc_client_secret` | `null` | Ephemeral secret, required when enabled |
| `oidc_client_secret_version` | `1` | Write-only secret rotation version |
| `oidc_path` | `oidc` | Authentication mount |
| `oidc_admin_role_name` | `admin` | Login role |
| `oidc_admin_group` | `vault-admins` | Required exact group |
| `oidc_admin_policy_name` | `super-admin` | Full-administration policy |

## Outputs

`kv_mounts` lists sorted mount names. `kubernetes_auth_path` identifies the auth
mount. `kubernetes_roles` maps roles to accounts, namespaces and policies.
`oidc_path` is null when disabled; `oidc_redirect_uris` lists callback URIs.

