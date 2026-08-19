# AGENTS.md -- aft-global-customizations

## Project Summary
AWS Account Factory for Terraform (AFT) global customizations. Applies baseline security, IAM, and logging resources to every AWS account provisioned through AFT in the `askattest` Terraform Cloud organization.

## Tech Stack
| Layer | Tool | Version Constraint |
|---|---|---|
| IaC | Terraform | >= 1.5.7 (mise pins 1.13.3) |
| Providers | `hashicorp/aws` | >= 6.15 |
| Providers | `hashicorp/tls` | ~> 4.0 |
| Private module | `askattest/s3-bucket/aws` | ~> 0.4 |
| Templating | Jinja2 (AFT runtime) | N/A |
| Linting | tflint | 0.59.1 |
| Security scanning | Trivy | 0.66.0 |
| Pre-commit | pre-commit-terraform | v1.100.0 |
| Toolchain manager | mise | see `mise.toml` |

## Repository Layout
```
.
├── terraform/
│   ├── main.tf              # Account alias, EBS encryption, S3 public access block
│   ├── roles.tf             # OIDC providers + IAM roles (TFC, GHA)
│   ├── s3.tf                # Logging buckets (access logs, VPC flow logs, LB logs)
│   ├── variables.tf         # (empty -- config via SSM data sources)
│   ├── versions.tf          # Terraform + provider version constraints
│   ├── aft-providers.jinja  # AFT-rendered provider config
│   └── backend.jinja        # AFT-rendered backend config
├── api_helpers/
│   ├── pre-api-helpers.sh   # Runs before Terraform apply (stub)
│   ├── post-api-helpers.sh  # Runs after Terraform apply (stub)
│   └── python/
│       └── requirements.txt # Python deps for API helpers (empty)
├── .pre-commit-config.yaml
├── mise.toml
├── docs/
│   └── ARCHITECTURE.md
├── AGENTS.md                # This file
├── CLAUDE.md
└── README.md
```

## Key Commands
```bash
# Install tool versions
mise install

# Run all pre-commit checks (fmt, tflint, trivy, whitespace)
mise run precommit

# Format Terraform
terraform fmt -recursive terraform/

# Lint
tflint --chdir=terraform/

# Security scan
trivy config --skip-dirs="**/.terraform" terraform/
```

## Development Workflow
1. Create a feature branch.
2. Edit Terraform files under `terraform/`.
3. Run `mise run precommit` to validate.
4. Open a pull request. AFT will plan/apply changes to all managed accounts on merge.

## Conventions
- See `.agents/rules/code-style.md` for formatting and naming conventions.
- See `.agents/rules/testing.md` for validation approach.
- See `.agents/rules/security.md` for security-sensitive resources and review requirements.

## Updating Documentation
When making changes that affect the repository structure, resource definitions, or security posture:
1. Update `docs/ARCHITECTURE.md` if the architecture changes.
2. Update this file (`AGENTS.md`) if the tech stack, layout, or commands change.
3. Update `README.md` if the user-facing description or usage instructions change.
