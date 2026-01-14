data "aws_ssm_parameter" "alias" {
  name = "/aft/account-request/custom-fields/account_alias"
}

resource "aws_iam_account_alias" "alias" {
  account_alias = data.aws_ssm_parameter.alias.value
}
