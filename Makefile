SHELL := /bin/bash

ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
EXAMPLE_DIR ?= terraform/examples/platform

.PHONY: fmt lint validate docs tools clean test-vault test-keycloak

fmt:
	@echo "▶ Terraform fmt (recursive)"
	@terraform fmt -recursive

lint:
	@echo "▶ TFLint"
	@tflint --recursive

validate:
	@echo "▶ Terraform validate (-backend=false) in $(EXAMPLE_DIR)"
	@terraform -chdir=$(EXAMPLE_DIR) init -backend=false >/dev/null
	@terraform -chdir=$(EXAMPLE_DIR) validate

docs:
	@echo "▶ terraform-docs for all modules"
	@find terraform/modules -maxdepth 2 -mindepth 2 -type d -print0 | xargs -0 -I {} terraform-docs markdown table {} > /dev/null
	@echo "   Run docs at module root to generate README sections."

tools: fmt lint validate

clean:
	@echo "▶ Removing .terraform caches from modules and examples"
	@find . -type d -name ".terraform" -prune -exec rm -rf {} +

# Does not contact a live Vault or use administrator credentials.
test-vault:
	terraform fmt -check -recursive terraform/modules/secrets/vault-platform
	terraform fmt -check -recursive terraform/examples/vault-platform
	terraform -chdir=terraform/modules/secrets/vault-platform init -backend=false
	terraform -chdir=terraform/modules/secrets/vault-platform validate
	terraform -chdir=terraform/modules/secrets/vault-platform test
	terraform -chdir=terraform/examples/vault-platform init -backend=false
	terraform -chdir=terraform/examples/vault-platform validate

# Mocked realm tests; no live identity provider or administrator credentials.
test-keycloak:
	terraform fmt -check -recursive terraform/modules/idp/keycloak-realm
	terraform -chdir=terraform/modules/idp/keycloak-realm init -backend=false
	terraform -chdir=terraform/modules/idp/keycloak-realm validate
	terraform -chdir=terraform/modules/idp/keycloak-realm test

# Mocked Cloudflare tests never contact a live account.
.PHONY: test-cloudflare
test-cloudflare:
	terraform fmt -check -recursive terraform/modules/dns/cloudflare-zones
	terraform fmt -check -recursive terraform/modules/network/cloudflare-zero-trust
	terraform fmt -check -recursive terraform/examples/cloudflare-adoption
	terraform -chdir=terraform/modules/dns/cloudflare-zones init -backend=false
	terraform -chdir=terraform/modules/dns/cloudflare-zones validate
	terraform -chdir=terraform/modules/dns/cloudflare-zones test
	terraform -chdir=terraform/modules/network/cloudflare-zero-trust init -backend=false
	terraform -chdir=terraform/modules/network/cloudflare-zero-trust validate
	terraform -chdir=terraform/modules/network/cloudflare-zero-trust test
	terraform -chdir=terraform/examples/cloudflare-adoption init -backend=false
	terraform -chdir=terraform/examples/cloudflare-adoption validate
