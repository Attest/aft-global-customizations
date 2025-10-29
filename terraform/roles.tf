# Terraform Cloud Deploy Role
terraform {
  required_version = ">= 1.5.0"
}

locals {
  tfc_org = "askattest"
}

############################
# OIDC provider for TFC
############################
data "tls_certificate" "provider" {
  url = "https://app.terraform.io"
}

resource "aws_iam_openid_connect_provider" "tfc" {
  url = "https://app.terraform.io"

  client_id_list = [
    "aws.workload.identity", # Default audience in HCP Terraform for AWS.
  ]

  thumbprint_list = [
    data.tls_certificate.provider.certificates[0].sha1_fingerprint,
  ]
}

############################
# IAM role TFC will assume (via OIDC)
############################
data "aws_iam_policy_document" "tfc_runner_assume_role_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.tfc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "app.terraform.io:aud"
      values   = ["aws.workload.identity"]
    }

    condition {
      test     = "StringLike"
      variable = "app.terraform.io:sub"
      values   = ["organization:${local.tfc_org}:project:*:workspace:*:run_phase:*"]
    }
  }
}

resource "aws_iam_role" "tfc_runner" {
  name = "terraform-cloud-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.tfc_runner_assume_role_policy.json
}

############################
# Permissions for the role
# - bootstrap with AdministratorAccess (simple)
############################

# Option A (toggle via var.attach_admin_policy)
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.tfc_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
