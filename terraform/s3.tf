# ---------------------------------------------------------------------------
# Alias ordering -- why every module below carries depends_on.
#
# askattest/s3-bucket/aws reads `data "aws_iam_account_alias" "current" {}`
# internally (its main.tf:43). `aws_iam_account_alias.alias` in main.tf is what
# CREATES that alias, from the SSM parameter AFT writes out of the account
# request's `custom_fields.account_alias`. Nothing ordered the read after the
# write, and a data source is evaluated during PLAN, so on an account whose
# alias does not exist yet the plan dies with
#
#   Error: reading IAM Account Alias: empty result
#
# before the alias can ever be created -- a deadlock no re-run escapes.
# MEASURED 2026-08-25 on `audit` (552533871415) and `security` (215600395829),
# the two Control Tower core accounts, six errors per run. The six accounts AFT
# provisioned earlier are unaffected only because their aliases predate this
# coupling, so the defect stayed hidden until an account was bootstrapped from
# scratch.
#
# depends_on on the module call defers everything inside it, data sources
# included, until the alias exists. It is INERT wherever the alias is already
# there: with no pending change on aws_iam_account_alias.alias, Terraform reads
# the data sources at plan time exactly as before, so the eight established
# accounts see an identical plan. The cost is only that on a first-ever run for
# a new account the bucket names are unknown until apply, which for a
# create-everything plan changes nothing that matters.
#
# The narrower fix belongs in askattest/s3-bucket/aws -- taking the alias as an
# optional input instead of reading it unconditionally -- and would also let the
# two `enable_access_logs = false` workarounds further down come out. That is a
# module release; this is the fix available in one repo.
# ---------------------------------------------------------------------------

locals {
  # set name prefix (via bucket application var) to be the account alias (passed in as a custom field in the account request modules)
  # this ensures all buckets created in the account have a unique name across all AWS accounts
  # example: aft-dr (full bucket: attest-aft-dr-s3-access-logs-a102) when the account alias is attest-ct-dr
  bucket_application = "aft-${trimprefix(data.aws_ssm_parameter.alias.value, "attest-ct-")}"
}

# S3 access logs bucket
module "s3_access_logs_bucket" {
  source  = "app.terraform.io/askattest/s3-bucket/aws"
  version = "~> 0.4"

  name                                            = "s3-access-logs"
  application                                     = local.bucket_application
  attach_access_log_delivery_policy               = true
  access_log_delivery_policy_source_organizations = [data.aws_organizations_organization.current.id]

  enable_access_logs = false # this is the logging bucket itself, so disable logging to avoid circular logging

  # See "Alias ordering" at the top of this file.
  depends_on = [aws_iam_account_alias.alias]
}

# VPC flow logs bucket
module "s3_vpc_flow_logs_bucket" {
  source  = "app.terraform.io/askattest/s3-bucket/aws"
  version = "~> 0.4"

  name        = "vpc-flow-logs"
  application = local.bucket_application
  logging = {
    target_bucket = module.s3_access_logs_bucket.bucket_id
    target_prefix = "vpc-flow-logs/"
  }

  # See "Alias ordering" at the top of this file.
  depends_on = [aws_iam_account_alias.alias]
}

# Load balancer access logs bucket
module "s3_lb_access_logs_bucket" {
  source  = "app.terraform.io/askattest/s3-bucket/aws"
  version = "~> 0.4"

  name        = "lb-access-logs"
  application = local.bucket_application
  logging = {
    target_bucket = module.s3_access_logs_bucket.bucket_id
    target_prefix = "lb-access-logs/"
  }
  attach_lb_log_delivery_policy               = true
  attach_elb_log_delivery_policy              = true
  lb_log_delivery_policy_source_organizations = [data.aws_organizations_organization.current.id]

  # See "Alias ordering" at the top of this file.
  depends_on = [aws_iam_account_alias.alias]
}

# ---------------------------------------------------------------------------
# eu-west-2 (DR region) log destinations
#
# The three buckets above are created in the account's home region, because that
# is the only region AFT generates a provider for. S3 server access logging
# requires the target bucket to be in the same Region as the source bucket, so a
# resource in eu-west-2 cannot log to any of them -- it needs a same-region
# destination. These exist in every account rather than only in dr so that
# standing anything up in eu-west-2 is a config change rather than a bootstrap.
#
# S3 bucket names are globally unique, and the home-region names above are already
# taken in this account. Rather than putting the region in the literal name, these
# pass name_suffix_seed, which is the module's own mechanism for this: a non-null
# seed makes it fold the account ID and region into the name-suffix hash. The
# literal name therefore matches its eu-west-1 counterpart and only the 4-char
# suffix differs.
#
# Consequence worth knowing: a seeded suffix is not derivable from the bucket name
# alone, so a consumer in another repo has to be given the full name rather than
# reconstructing it. That is why the vpc module is gaining an explicit
# flow_log_bucket_name argument rather than a seed argument.
#
# The buckets are cheap to leave empty; the cost of not having them is a failed
# plan at the moment someone needs one.
# ---------------------------------------------------------------------------

locals {
  # e.g. "aft-dr-eu-west-2". Passing a non-null name_suffix_seed is what switches the
  # module from its legacy name-only hash to one that folds in account ID and region,
  # so uniqueness does not depend on what we put here. Naming the seed after the
  # application and region anyway keeps these bucket names independent of that
  # internal behaviour instead of relying on it, and makes adding a second region a
  # copy-paste. The region is a literal because data.aws_region under the default
  # provider would resolve to the account's home region, not this one.
  eu_west_2_suffix_seed = "${local.bucket_application}-eu-west-2"
}

module "s3_access_logs_bucket_eu_west_2" {
  source    = "app.terraform.io/askattest/s3-bucket/aws"
  version   = "~> 0.4"
  providers = { aws = aws.eu_west_2 }

  name                                            = "s3-access-logs"
  application                                     = local.bucket_application
  name_suffix_seed                                = local.eu_west_2_suffix_seed
  attach_access_log_delivery_policy               = true
  access_log_delivery_policy_source_organizations = [data.aws_organizations_organization.current.id]

  enable_access_logs = false # this is the logging bucket itself, so disable logging to avoid circular logging

  # See "Alias ordering" at the top of this file.
  depends_on = [aws_iam_account_alias.alias]
}

# VPC flow logs bucket for eu-west-2. Consumed by vpc/dr in
# aws-foundation-control-tower, the first VPC in the org outside its account's
# home region.
module "s3_vpc_flow_logs_bucket_eu_west_2" {
  source    = "app.terraform.io/askattest/s3-bucket/aws"
  version   = "~> 0.4"
  providers = { aws = aws.eu_west_2 }

  name             = "vpc-flow-logs"
  application      = local.bucket_application
  name_suffix_seed = local.eu_west_2_suffix_seed

  # INERT until askattest/s3-bucket/aws is fixed, and deliberately left in place so
  # enabling it is a one-line change. That module derives the access-logs bucket name
  # from the account alias with no region component, and looks it up unconditionally
  # whenever enable_access_logs is true -- so in eu-west-2 the lookup misses the
  # home-region bucket and fails the plan. It also discards an explicit logging block
  # when enable_access_logs is false. Once the lookup honours an explicit target,
  # delete the enable_access_logs line below and this logging block starts applying.
  logging = {
    target_bucket = module.s3_access_logs_bucket_eu_west_2.bucket_id
    target_prefix = "vpc-flow-logs/"
  }
  enable_access_logs = false

  # See "Alias ordering" at the top of this file.
  depends_on = [aws_iam_account_alias.alias]
}

# Load balancer access logs bucket for eu-west-2. A DR rebuild serves traffic, which
# means load balancers in this region, which need a same-region log destination.
module "s3_lb_access_logs_bucket_eu_west_2" {
  source    = "app.terraform.io/askattest/s3-bucket/aws"
  version   = "~> 0.4"
  providers = { aws = aws.eu_west_2 }

  name             = "lb-access-logs"
  application      = local.bucket_application
  name_suffix_seed = local.eu_west_2_suffix_seed

  # Inert for the same reason as the flow logs bucket above.
  logging = {
    target_bucket = module.s3_access_logs_bucket_eu_west_2.bucket_id
    target_prefix = "lb-access-logs/"
  }
  enable_access_logs = false

  attach_lb_log_delivery_policy               = true
  attach_elb_log_delivery_policy              = true
  lb_log_delivery_policy_source_organizations = [data.aws_organizations_organization.current.id]

  # See "Alias ordering" at the top of this file.
  depends_on = [aws_iam_account_alias.alias]
}
