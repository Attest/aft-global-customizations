# Security

## Sensitive Resources
- **IAM roles with broad permissions**: `terraform-cloud-deploy-role` has `AdministratorAccess`; `github-actions-deploy-role` has `PowerUserAccess`. Changes to `roles.tf` require careful review.
- **OIDC trust policies**: Scoped to `organization:askattest:*` (TFC) and `repo:Attest/*` (GHA). Do not widen these conditions without security approval.
- **S3 account public access block** (`main.tf`): Blocks all public S3 access account-wide. Do not disable.
- **EBS encryption by default** (`main.tf`): Enforces encryption on all new EBS volumes. Do not disable.

## Secrets Management
- No secrets are stored in this repository.
- Account alias is read from AWS SSM Parameter Store at `/aft/account-request/custom-fields/account_alias`.
- Provider credentials are injected at runtime by AFT via assumed roles (see `aft-providers.jinja`).

## Scanning
- **Trivy** runs via pre-commit to catch misconfigurations in Terraform files.
- **tflint** catches deprecated syntax and provider-specific issues.

## Rules
- Never commit `.tfvars`, credentials, or secrets.
- Never remove the S3 public access block or EBS encryption default without explicit security approval.
- Any change to IAM trust policies or attached policies must be reviewed by the Platform team.
