locals {
  # set name prefix to be the account alias (passed in as a custom field in the account request modules)
  # this ensures all buckets created in the account have a unique name across all AWS accounts
  bucket_name_prefix = "data.aws_ssm_parameter.alias.value"
}

# S3 access logs bucket
module "s3_access_logs_bucket" {
  source  = "app.terraform.io/askattest/s3-bucket/aws"
  version = "~> 0.2"

  name        = "${local.bucket_name_prefix}-s3-access-logs"
  application = local.application
}

# VPC flow logs bucket
module "s3_vpc_flow_logs_bucket" {
  source  = "app.terraform.io/askattest/s3-bucket/aws"
  version = "~> 0.2"

  name        = "${local.bucket_name_prefix}-vpc-flow-logs"
  application = local.application
}

# Load balancer access logs bucket
module "s3_lb_access_logs_bucket" {
  source  = "app.terraform.io/askattest/s3-bucket/aws"
  version = "~> 0.2"

  name        = "${local.bucket_name_prefix}-vpc-flow-logs"
  application = local.application
}
