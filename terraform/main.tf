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

# EBS encryption-by-default is a per-region setting, so the resource above only ever
# covered the account's home region. Measured 2026-08-19 in the dr account:
# eu-west-1 True, eu-west-2 False. A DR rebuild creates EKS node volumes and restores
# data into eu-west-2, so without this those volumes come up unencrypted unless every
# caller remembers to ask.
#
# Only affects volumes created after it applies; existing volumes are untouched.
resource "aws_ebs_encryption_by_default" "ebs_eu_west_2" {
  provider = aws.eu_west_2
  enabled  = true
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
