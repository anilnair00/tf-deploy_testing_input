locals {
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

  default_tags_map = jsonencode({
    for tag in local.default_tags_list : split(":", tag)[0] => split(":", tag)[1]
  })

  dev_pipeline_yaml = <<-EOT
    pipeline:
      name: ${var.dev_pipeline_name}
      identifier: ${replace(var.dev_pipeline_name, "-", "")}
      projectIdentifier: ${var.project_id}
      orgIdentifier: ${var.org_id}
      tags: ${local.default_tags_map}
      template:
        templateRef: devcdkdeploy
        versionLabel: "1"
        gitBranch: main
        templateInputs:
          stages:
            - stage:
                identifier: cdkdeployint
                type: Custom
                spec:
                  environment:
                    environmentRef: <+input>
                    environmentInputs: <+input>
                    infrastructureDefinitions: <+input>
                  execution:
                    steps:
                      - stepGroup:
                          identifier: CDK_Diff
                          steps:
                            - step:
                                identifier: Git_Clone
                                type: GitClone
                                spec:
                                  connectorRef: <+input>
                                  repoName: <+input>
                                  resources:
                                    limits:
                                      memory: <+input>
                                      cpu: <+input>
                                  build:
                                    type: branch
                                    spec:
                                      branch: <+input>
                            - step:
                                identifier: AWS_CDK_Diff
                                type: Run
                                spec:
                                  connectorRef: <+input>
                                  image: <+input>
                                  envVariables:
                                    CDK_DEPLOYMENT_IAM_ROLE: <+input>
                                  resources:
                                    limits:
                                      memory: <+input>
                                      cpu: <+input>
                          stepGroupInfra:
                            type: KubernetesDirect
                            spec:
                              connectorRef: <+input>
                              namespace: <+input>
                              serviceAccountName: <+input>
                      - step:
                          identifier: CDK_Approval
                          type: HarnessApproval
                          spec:
                            approvers:
                              userGroups: <+input>
                              minimumCount: <+input>
                      - stepGroup:
                          identifier: CDK_Deploy
                          steps:
                            - step:
                                identifier: Git_Clone
                                type: GitClone
                                spec:
                                  connectorRef: <+input>
                                  repoName: <+input>
                                  resources:
                                    limits:
                                      memory: <+input>
                                      cpu: <+input>
                                  build:
                                    type: branch
                                    spec:
                                      branch: <+input>
                            - step:
                                identifier: AWS_CDK_Application_Deploy
                                type: Run
                                spec:
                                  connectorRef: <+input>
                                  image: <+input>
                                  envVariables:
                                    CDK_DEPLOYMENT_IAM_ROLE: <+input>
                                  resources:
                                    limits:
                                      memory: <+input>
                                      cpu: <+input>
                          stepGroupInfra:
                            type: KubernetesDirect
                            spec:
                              connectorRef: <+input>
                              namespace: <+input>
                              serviceAccountName: <+input>
  EOT
}

module "dev_pipeline" {
  source = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-cdk-pipelines?ref=develop"

  name                 = var.dev_pipeline_name
  identifier           = replace(var.dev_pipeline_name, "-", "")
  org_id               = var.org_id
  project_id           = var.project_id
  branch_name          = var.harness_templates_branch_name
  file_path            = replace("pipelines/cdk/${var.dev_pipeline_name}.yaml", "-", "")
  repository_connector = var.devops_repository_connector
  store_type           = "REMOTE"
  repository_name      = var.harness_templates_repo_name
  yaml                 = local.dev_pipeline_yaml
  tags                 = local.default_tags_list
}