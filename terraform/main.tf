data "aws_ssm_parameter" "alias" {
  name = "/aft/account-request/custom-fields/account_alias"
}

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
