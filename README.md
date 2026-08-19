# aft-global-customizations

AFT (Account Factory for Terraform) global customizations for the `askattest` organization. These Terraform resources are applied to **every** AWS account provisioned through AFT.

## What This Repo Does

Applies the following baseline to each account:

- **Account alias** -- set from the AFT account request custom field in SSM
- **EBS encryption by default** -- all new EBS volumes are encrypted
- **S3 account public access block** -- prevents any bucket from being made public
- **OIDC IAM roles** -- `terraform-cloud-deploy-role` (TFC) and `github-actions-deploy-role` (GHA)
- **Logging S3 buckets** -- s3-access-logs, vpc-flow-logs, lb-access-logs

## Prerequisites

Install tooling via [mise](https://mise.jdx.dev/):

```bash
mise install
```

This installs Terraform, tflint, Trivy, terraform-docs, Python, and pre-commit as specified in `mise.toml`.

## Usage

Edit Terraform files under `terraform/`, then validate:

```bash
mise run precommit
```

AFT automatically applies changes to all managed accounts on merge to `main`.

### Terraform

Place `.tf` files in the `terraform/` directory. AFT renders `aft-providers.jinja` and `backend.jinja` at runtime to configure the provider and backend.

### API Helpers

- `api_helpers/pre-api-helpers.sh` -- runs before `terraform apply`
- `api_helpers/post-api-helpers.sh` -- runs after `terraform apply`
- `api_helpers/python/requirements.txt` -- Python dependencies installed via pip

## Documentation

- [AGENTS.md](AGENTS.md) -- AI agent instructions, tech stack, commands, and conventions
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) -- Architecture overview with Mermaid diagrams

## License

Mozilla Public License 2.0 -- see [LICENSE](LICENSE).
