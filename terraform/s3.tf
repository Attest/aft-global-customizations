locals {
  # set name prefix (via bucket application var) to be the account alias (passed in as a custom field in the account request modules)
  # this ensures all buckets created in the account have a unique name across all AWS accounts
  bucket_application = data.aws_ssm_parameter.alias.value
}

# S3 access logs bucket
module "s3_access_logs_bucket" {
  source  = "app.terraform.io/askattest/s3-bucket/aws"
  version = "~> 0.2"

  name        = "s3-access-logs"
  application = local.bucket_application
}

# VPC flow logs bucket
module "s3_vpc_flow_logs_bucket" {
  source  = "app.terraform.io/askattest/s3-bucket/aws"
  version = "~> 0.2"

  name        = "vpc-flow-logs"
  application = local.bucket_application
}

# Load balancer access logs bucket
module "s3_lb_access_logs_bucket" {
  source  = "app.terraform.io/askattest/s3-bucket/aws"
  version = "~> 0.2"

  name        = "lb-access-logs"
  application = local.bucket_application
}
