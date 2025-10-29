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
resource "aws_iam_openid_connect_provider" "tfc" {
  url             = "https://app.terraform.io"
  client_id_list  = ["aws"]                           # Terraform Cloud sets aud=aws
}

############################
# IAM role TFC will assume (via OIDC)
############################
resource "aws_iam_role" "tfc_runner" {
  name = "terraform-cloud-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.tfc.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "app.terraform.io:aud" = "aws"
          },
          # Allow one or many subjects (org/project/workspace) using ForAnyValue:StringLike
          "ForAnyValue:StringLike" = {
            "app.terraform.io:sub" = "organization:${local.tfc_org}:project:*:workspace:*:run_phase:*"
          }
        }
      }
    ]
  })
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
