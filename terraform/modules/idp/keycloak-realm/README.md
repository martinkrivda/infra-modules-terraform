# idp/keycloak-realm

Manage one existing Keycloak realm, interactive OIDC clients, a shared flat
`groups` claim, groups, users, memberships and optional realm roles. This module
configures realm content only; it does not deploy Keycloak or consumers.

Requires Terraform >= 1.7, < 2 and `keycloak/keycloak` ~> 5.7. Supply the provider
from the caller. No provider credentials or environment identities are embedded.

PUBLIC clients require S256. Confidential clients opt in through
`pkce_required` only after consumer support is verified. Interactive clients
always use code flow; implicit, direct password grants and service accounts are
disabled. Callbacks must be explicit HTTPS; the only HTTP exception is
`http://localhost:8250/oidc/callback` for client `vault`. Logout callbacks and
web origins have separate strict validation. Empty web origins are supported.

The realm enables temporary brute-force lockouts and a 14-character password
policy with username/email exclusion and password history. TOTP policy is
configured, but enrollment must be requested through a user's
`required_actions = ["UPDATE_PASSWORD", "CONFIGURE_TOTP"]`. Verify the actual
browser flow requires OTP; this module does not replace custom browser flows.
After successful enrollment clear bootstrap actions to avoid adding them again.
No user password input/resource is supported. Existing email verification is
never assumed. All groups referenced by users and roles must be managed here.

Memberships, default client scopes and group role assignments are authoritative.
Import existing objects before applying. Confidential client secrets and SMTP
passwords remain in state even though secret outputs are marked sensitive.

## Office Lab source migration

This module was moved from `officelab-keycloak-terraform/modules/keycloak` with
the same resource types, names and for_each keys. Keep the caller named
`module.keycloak`, its inputs, backend and original state. Changing only the
source requires `terraform init` and plan review; no moved blocks or state
replacement are required. Never infer that absent state means an empty server.
Publish the catalog changes before using the GitHub source, then pin the
consumer source to the published immutable commit. No commit or push is
performed by this migration workflow.

The older multi-realm `idp/keycloak-config` interface remains unchanged for
existing consumers; it is not interchangeable with this module.

## Tests

`terraform init -backend=false`, `terraform validate`, `terraform test`.
Tests use a mocked provider and never contact Keycloak. They cover invalid URL
boundaries, grants, PKCE, memberships, role references, SMTP and MFA bootstrap.

## Interface

| Inputs | Purpose |
| --- | --- |
| `realm_name`, `realm_display_name`, `realm_login_theme` | Realm identity and display |
| `smtp_server` | Optional SMTP; includes sensitive state material |
| `clients` | Typed interactive client list, callbacks, origins, optional PKCE |
| `groups`, `users` | Flat group names, identities, required actions and memberships |
| `realm_roles`, `group_realm_roles` | Optional managed realm roles and group assignments |

Outputs: `realm_id`, `group_ids`, `client_ids`, sensitive `client_secrets`,
`user_ids`, and non-secret integration contracts `client_configuration`,
`groups_claim`, `user_access`.

The interface table was maintained manually because terraform-docs was not
available in the validation environment; regenerate it with the catalog docs
tooling when available.
