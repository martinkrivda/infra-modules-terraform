# Vault platform bootstrap

This example configures an existing, initialized and unsealed Vault running
inside the same Kubernetes cluster. It does not install Vault, initialize it,
create Kubernetes RBAC, or populate secret values.

Supply `TF_VAR_vault_address` and administrator credentials through `VAULT_TOKEN`
or an existing Vault CLI login. Run `terraform init`, then review `terraform plan`.
Use the existing state and import already existing objects before the first apply.
The Vault service account must be allowed to create TokenReviews.

OIDC is disabled for bootstrap. Enable it only after configuring the identity
provider, passing its HTTPS issuer, client ID, group and ephemeral client secret.
