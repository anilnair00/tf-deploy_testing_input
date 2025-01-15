locals {
  envs                           = var.envs
  account_names                  = var.account_names
  cross_account_role_arns        = var.cross_account_role_arns
  env_account_map                = zipmap(local.envs, local.account_names)
  env_cross_account_role_arn_map = zipmap(local.envs, local.cross_account_role_arns)

  default_tags_list = [
    "CostCode/AFC:1904",
    "Tower:operation",
    "DepartmentID:1904",
    "DepartmentName:ops-digital",
    "ProjectName:Notification",
    "Application:ACNP",
    "TechOwner:Azeem Qaiser",
    "BusinessOwner:Pradeep Nishantha",
    "Criticality:Critical",
    "Sensitivity:High",
    "ManagedBy:Terraform",
    "tf-repo-name:ac-it-notifications-harness-resources-tf"
  ]

  connectors = flatten([
    for env in local.envs : {
      identifier                    = "${replace(local.env_account_map[env], "-", "")}appconnector"
      name                          = "${local.env_account_map[env]}-app-connector"
      description                   = "${local.env_account_map[env]} app connector"
      org_id                        = var.org_id
      project_id                    = var.project_id
      cross_account_access_role_arn = local.env_cross_account_role_arn_map[env]
      harnessdelegate               = env == "prod" ? var.kubernetes_delegate_prod : var.kubernetes_delegate_nonprod
      region                        = var.region
    }
  ])
}

module "aws_irsa_connectors" {
  source     = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-aws-irsa-connectors?ref=develop"
  connectors = local.connectors
  tags       = local.default_tags_list
}