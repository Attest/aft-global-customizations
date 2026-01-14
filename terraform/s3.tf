locals {
  # set name prefix (via bucket application var) to be the account alias (passed in as a custom field in the account request modules)
  # this ensures all buckets created in the account have a unique name across all AWS accounts
  # example: aft-dr (full bucket: attest-aft-dr-s3-access-logs-a102) when the account alias is attest-ct-dr
  bucket_application = "aft-${trimprefix(data.aws_ssm_parameter.alias.value, "attest-ct-")}"
}

# S3 access logs bucket
module "s3_access_logs_bucket" {
  source  = "app.terraform.io/askattest/s3-bucket/aws"
  version = "~> 0.3"

  name        = "s3-access-logs"
  application = local.bucket_application

  enable_access_logs = false # this is the logging bucket itself, so disable logging to avoid circular logging
}

# VPC flow logs bucket
module "s3_vpc_flow_logs_bucket" {
  source  = "app.terraform.io/askattest/s3-bucket/aws"
  version = "~> 0.3"

  name        = "vpc-flow-logs"
  application = local.bucket_application
  logging = {
    target_bucket = module.s3_access_logs_bucket.bucket_id
    target_prefix = "vpc-flow-logs/"
  }
}

# Load balancer access logs bucket
module "s3_lb_access_logs_bucket" {
  source  = "app.terraform.io/askattest/s3-bucket/aws"
  version = "~> 0.3"

  name        = "lb-access-logs"
  application = local.bucket_application
  logging = {
    target_bucket = module.s3_access_logs_bucket.bucket_id
    target_prefix = "lb-access-logs/"
  }
}
