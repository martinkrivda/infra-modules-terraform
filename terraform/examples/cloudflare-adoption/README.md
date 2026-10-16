# Cloudflare adoption composition

This credential-free example composes the DNS and Zero Trust modules with empty
maps. Supply the account ID to plan; credentials come from `CLOUDFLARE_API_TOKEN`.
Populate maps with exact remote configuration and import existing IDs before any
apply. See the two module READMEs for shapes and import formats.

Run `make test-cloudflare` from the catalog root for formatting, module validation,
mocked adoption tests and example validation, using Terraform >= 1.11. Mocked
tests only plan, so protected resources never require teardown. No test contacts
Cloudflare.
