# Testing

## Current State
This repository has no automated test suite. Validation relies on:

1. **Pre-commit hooks** -- `terraform_fmt`, `terraform_tflint`, and `terraform_trivy` run on every commit.
2. **Terraform plan** -- AFT runs `terraform plan` before applying to each target account.
3. **Manual review** -- Pull request review before merge.

## Validation Commands
```bash
# Format check
terraform fmt -check -recursive terraform/

# Lint
tflint --chdir=terraform/

# Security scan
trivy config --skip-dirs="**/.terraform" terraform/

# Run all pre-commit hooks
mise run precommit
```

## Adding Tests
<!-- TODO: human please fill in if/when a test framework (e.g., Terratest, terraform test) is adopted -->
