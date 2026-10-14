SHELL := /bin/bash

ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
EXAMPLE_DIR ?= terraform/examples/platform

.PHONY: fmt lint validate docs tools clean test-vault

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
