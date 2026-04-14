data "aws_ssm_parameter" "alias" {
  name = "/aft/account-request/custom-fields/account_alias"
}

data "aws_organizations_organization" "current" {}

resource "aws_iam_account_alias" "alias" {
  account_alias = data.aws_ssm_parameter.alias.value
}

resource "aws_ebs_encryption_by_default" "ebs" {
  enabled = true
}

resource "aws_s3_account_public_access_block" "s3_public_access_block" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# EC2 Spot service-linked role - required for Karpenter to provision spot instances
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
  description      = "Service-linked role for EC2 Spot Instances"
}
