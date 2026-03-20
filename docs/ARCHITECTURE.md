# Architecture -- aft-global-customizations

## Overview
This repository defines baseline resources that AFT (Account Factory for Terraform) applies to **every** AWS account it provisions. AFT clones this repo, renders the Jinja templates, and runs `terraform apply` against each target account.

## Execution Flow

```mermaid
sequenceDiagram
    participant AFT as AFT Pipeline
    participant Repo as aft-global-customizations
    participant Target as Target AWS Account

    AFT->>Repo: Clone repo
    AFT->>Repo: Render backend.jinja & aft-providers.jinja
    AFT->>Target: Run pre-api-helpers.sh
    AFT->>Target: terraform init + plan + apply
    AFT->>Target: Run post-api-helpers.sh
```

## Resource Map

```mermaid
graph TD
    subgraph "main.tf -- Account Baseline"
        A1[aws_iam_account_alias]
        A2[aws_ebs_encryption_by_default]
        A3[aws_s3_account_public_access_block]
    end

    subgraph "roles.tf -- OIDC & IAM"
        B1[OIDC Provider: Terraform Cloud]
        B2[IAM Role: terraform-cloud-deploy-role<br/>AdministratorAccess]
        B3[OIDC Provider: GitHub Actions]
        B4[IAM Role: github-actions-deploy-role<br/>PowerUserAccess]
        B1 --> B2
        B3 --> B4
    end

    subgraph "s3.tf -- Logging Buckets"
        C1[S3: s3-access-logs]
        C2[S3: vpc-flow-logs]
        C3[S3: lb-access-logs]
        C2 -->|logs to| C1
        C3 -->|logs to| C1
    end

    SSM[SSM Parameter<br/>/aft/account-request/custom-fields/account_alias]
    SSM --> A1
    SSM --> C1
    SSM --> C2
    SSM --> C3
```

## Data Sources
| Source | Used By | Purpose |
|---|---|---|
| `aws_ssm_parameter.alias` | `main.tf`, `s3.tf` | Account alias from AFT custom fields |
| `aws_organizations_organization.current` | `s3.tf` | Org ID for S3 log delivery policies |
| `tls_certificate.provider` | `roles.tf` | TFC OIDC thumbprint |

## Private Module Dependencies
| Module | Registry | Version | Used In |
|---|---|---|---|
| `askattest/s3-bucket/aws` | `app.terraform.io` | ~> 0.4 | `s3.tf` |

## Security Controls Applied Per Account
1. **EBS encryption by default** -- all new EBS volumes are encrypted.
2. **S3 account public access block** -- prevents any S3 bucket from being made public.
3. **IAM account alias** -- set from the AFT account request custom field.
4. **OIDC-based IAM roles** -- no long-lived credentials for TFC or GHA.

## Jinja Templates (AFT-Rendered)
- `aft-providers.jinja` -- Configures the AWS provider to assume the target account admin role. Adds default tags: `Application=AFT`, `ManagedBy=AFT-Terraform`, `gitRepo=aft-global-customizations`, `Owner=Platform`.
- `backend.jinja` -- Configures S3 backend (Terraform OSS) or remote backend (Terraform Cloud) depending on `tf_distribution_type`.
