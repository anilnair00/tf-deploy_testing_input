locals {
  envs            = var.envs
  account_names   = var.account_names
  env_account_map = zipmap(local.envs, local.account_names)

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

  infrastructures = flatten([
    for env in local.envs : {
      identifier           = "${replace(local.env_account_map[env], "-", "")}cdk"
      name                 = "${local.env_account_map[env]}-cdk"
      org_id               = var.org_id
      project_id           = var.project_id
      env_id               = "${replace(env, "-", "")}"
      deployment_type      = var.deployment_type
      env_type             = var.deployment_type
      store_type           = "REMOTE"
      repository_connector = var.devops_repository_connector
      repository_name      = var.harness_templates_repo_name
      file_path            = "${replace("infrastructures/cdk/${local.env_account_map[env]}cdk.yaml", "-", "")}"
      branch_name          = var.harness_templates_branch_name
      yaml                 = <<-EOT
        infrastructureDefinition:
          name: ${local.env_account_map[env]}-cdk
          identifier: ${replace(local.env_account_map[env], "-", "")}cdk
          orgIdentifier: ${var.org_id}
          projectIdentifier: ${var.project_id}
          tags: {
                "CostCode/AFC":"1904",
                "Tower":"operation",
                "DepartmentID":"1904",
                "DepartmentName":"ops-digital",
                "ProjectName":"Notification",
                "Application":"ACNP",
                "TechOwner":"Azeem Qaiser",
                "BusinessOwner":"Pradeep Nishantha",
                "Criticality":"Critical",
                "Sensitivity":"High",
                "ManagedBy":"Terraform",
                "tf-repo-name":"ac-it-notifications-harness-resources-tf"
          }
          environmentRef: ${replace(env, "-", "")}
          deploymentType: ${var.deployment_type}
          type: ${var.deployment_type}
          spec:
            connectorRef: <+input>
            stage: <+input>
            region: <+input>
          allowSimultaneousDeployments: false
      EOT
    }
  ])
}

module "infrastructures" {
  source = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-cdk-infrastructure?ref=develop"

  infrastructures = local.infrastructures
  tags            = local.default_tags_list
}