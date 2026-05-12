# Repository Guidelines

## Project Structure & Module Organization
This repository is a Terraform module catalog for a self-hosted platform. Reusable modules live under `terraform/modules/`, grouped by domain: `compute/`, `db/`, `dns/`, `k8s/`, `idp/`, and `secrets/`. Each module should keep its interface and docs local with `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`; split implementation files such as `database.tf` or `vault.tf` are acceptable when they clarify ownership. Example compositions live in `terraform/examples/`, with `terraform/examples/platform` used by the default validation target. Keep environment-specific values, backends, `*.tfvars`, and secrets out of this repo.

## Build, Test, and Development Commands
- `make fmt`: runs `terraform fmt -recursive` across modules and examples.
- `make lint`: runs `tflint --recursive` using `.tflint.hcl`.
- `make validate`: initializes `terraform/examples/platform` with `-backend=false` and runs `terraform validate`.
- `make tools`: runs `fmt`, `lint`, and `validate` in sequence.
- `pre-commit run --all-files`: runs Terraform fmt/validate/tflint/docs, Trivy, YAML linting, and whitespace checks.
- `make clean`: removes `.terraform` caches from modules and examples.

## Coding Style & Naming Conventions
Use 2-space indentation, LF line endings, final newlines, and no trailing whitespace as defined in `.editorconfig`; Makefile recipes use tabs. Terraform identifiers must use `snake_case`, matching the TFLint naming rule. Prefer explicit variable descriptions, validations, and typed inputs. Keep modules generic and parameterized; pass provider credentials, IPs, domains, and secret material from consuming environment repositories.

## Testing Guidelines
There is no unit test framework; validation is static and example-based. Before opening a PR, run `make tools` and preferably `pre-commit run --all-files`. When adding or changing a module, update its README with `terraform-docs` output and add or adjust an example when the behavior is not obvious from variables alone.

## Commit & Pull Request Guidelines
Recent history uses short imperative messages, often Conventional Commit-style prefixes such as `feat:`, `feat(db):`, `fix:`, and `chore:`. Follow that pattern, for example `feat(k8s): add namespace quotas`. Pull requests should describe the module impact, list validation commands run, link related issues, and call out provider or state migration implications. Include screenshots only when documentation rendering or generated diagrams changed.

## Security & Configuration Tips
Never commit secrets, real environment values, local state, or generated provider credentials. Use Vault-oriented module outputs and references instead of embedding sensitive values. Treat this repo as versioned shared infrastructure code: changes to inputs, outputs, resource names, or defaults may affect downstream Terraform state and should be documented in the PR.
