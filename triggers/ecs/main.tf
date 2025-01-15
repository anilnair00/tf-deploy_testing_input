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

  default_tags_map = jsonencode({
    for tag in local.default_tags_list : split(":", tag)[0] => split(":", tag)[1]
  })

  yaml_config = yamldecode(file("${path.module}/triggers.yaml"))

  feature_push_triggers = flatten([
    for repo, apps in local.yaml_config : [
      for app_key, app_value in apps : {
        name       = "${repo}-${app_key}-pipeline-trigger"
        identifier = "${replace("${repo}-${app_key}-pipeline-trigger", "-", "")}"
        org_id     = var.org_id
        project_id = var.project_id
        target_id  = "${replace(var.feature_pipeline_name, "-", "")}"
        yaml       = <<-EOT
          trigger:
            name: ${repo}-${app_key}-pipeline-trigger
            identifier: ${replace("${repo}-${app_key}-pipeline-trigger", "-", "")}
            enabled: true
            encryptedWebhookSecretIdentifier: ""
            description: "feature pipeline push trigger"
            tags: ${local.default_tags_map}
            orgIdentifier: ${var.org_id}
            stagesToExecute: []
            projectIdentifier: ${var.project_id}
            pipelineIdentifier: ${replace(var.feature_pipeline_name, "-", "")}
            source:
              type: Webhook
              spec:
                type: Github
                spec:
                  type: Push
                  spec:
                    connectorRef: ${var.repository_connector}
                    autoAbortPreviousExecutions: false
                    payloadConditions:
                      - key: changedFiles
                        operator: Regex
                        value: ^(apps\/${app_key}\/.*|environments\/int\/${app_key}\/.*)$
                      - key: targetBranch
                        operator: StartsWith
                        value: feature
                    headerConditions: []
                    repoName: ${repo}
                    actions: []
            inputSetRefs:
              - ${replace("${repo}-${app_key}-is", "-", "")}
  EOT
      }
    ]
  ])

  dev_pr_triggers = flatten([
    for repo, apps in local.yaml_config : [
      for app_key, app_value in apps : {
        name       = "${repo}-${app_key}-pipeline-trigger"
        identifier = "${replace("${repo}-${app_key}-pipeline-trigger", "-", "")}"
        org_id     = var.org_id
        project_id = var.project_id
        target_id  = "${replace(var.dev_pipeline_name, "-", "")}"
        yaml       = <<-EOT
          trigger:
            name: ${repo}-${app_key}-pipeline-trigger
            identifier: ${replace("${repo}-${app_key}-pipeline-trigger", "-", "")}
            enabled: true
            encryptedWebhookSecretIdentifier: ""
            description: "dev pipeline pull request trigger"
            tags: ${local.default_tags_map}
            orgIdentifier: ${var.org_id}
            stagesToExecute: []
            projectIdentifier: ${var.project_id}
            pipelineIdentifier: ${replace(var.dev_pipeline_name, "-", "")}
            source:
              type: Webhook
              spec:
                type: Github
                spec:
                  type: PullRequest
                  spec:
                    connectorRef: ${var.repository_connector}
                    autoAbortPreviousExecutions: false
                    payloadConditions:
                      - key: targetBranch
                        operator: Equals
                        value: develop
                      - key: sourceBranch
                        operator: StartsWith
                        value: feature
                      - key: changedFiles
                        operator: Regex
                        value: ^(apps\/${app_key}\/.*|environments\/int\/${app_key}\/.*)$
                    headerConditions: []
                    repoName: ${repo}
                    actions:
                      - Close
            inputSetRefs:
              - ${replace("${repo}-${app_key}-is", "-", "")}
  EOT
      }
    ]
  ])

  bat_pr_triggers = flatten([
    for repo, apps in local.yaml_config : [
      for app_key, app_value in apps : {
        name       = "${repo}-${app_key}-pipeline-trigger"
        identifier = "${replace("${repo}-${app_key}-pipeline-trigger", "-", "")}"
        org_id     = var.org_id
        project_id = var.project_id
        target_id  = "${replace(var.bat_pipeline_name, "-", "")}"
        yaml       = <<-EOT
          trigger:
            name: ${repo}-${app_key}-pipeline-trigger
            identifier: ${replace("${repo}-${app_key}-pipeline-trigger", "-", "")}
            enabled: true
            encryptedWebhookSecretIdentifier: ""
            description: "bat pipeline pull request trigger"
            tags: ${local.default_tags_map}
            orgIdentifier: ${var.org_id}
            stagesToExecute: []
            projectIdentifier: ${var.project_id}
            pipelineIdentifier: ${replace(var.bat_pipeline_name, "-", "")}
            source:
              type: Webhook
              spec:
                type: Github
                spec:
                  type: PullRequest
                  spec:
                    connectorRef: ${var.repository_connector}
                    autoAbortPreviousExecutions: false
                    payloadConditions:
                      - key: targetBranch
                        operator: Equals
                        value: bat
                      - key: sourceBranch
                        operator: Equals
                        value: develop
                      - key: changedFiles
                        operator: Regex
                        value: ^(apps\/${app_key}\/.*|environments\/bat\/${app_key}\/.*)$
                    headerConditions: []
                    repoName: ${repo}
                    actions:
                      - Close
            inputSetRefs:
              - ${replace("${repo}-${app_key}-is", "-", "")}
  EOT
      }
    ]
  ])

  release_pr_triggers = flatten([
    for repo, apps in local.yaml_config : [
      for app_key, app_value in apps : {
        name       = "${repo}-${app_key}-pipeline-trigger"
        identifier = "${replace("${repo}-${app_key}-pipeline-trigger", "-", "")}"
        org_id     = var.org_id
        project_id = var.project_id
        target_id  = "${replace(var.release_pipeline_name, "-", "")}"
        yaml       = <<-EOT
          trigger:
            name: ${repo}-${app_key}-pipeline-trigger
            identifier: ${replace("${repo}-${app_key}-pipeline-trigger", "-", "")}
            enabled: true
            encryptedWebhookSecretIdentifier: ""
            description: "release pipeline pull request trigger"
            tags: ${local.default_tags_map}
            orgIdentifier: ${var.org_id}
            stagesToExecute: []
            projectIdentifier: ${var.project_id}
            pipelineIdentifier: ${replace(var.release_pipeline_name, "-", "")}
            source:
              type: Webhook
              spec:
                type: Github
                spec:
                  type: PullRequest
                  spec:
                    connectorRef: ${var.repository_connector}
                    autoAbortPreviousExecutions: false
                    payloadConditions:
                      - key: targetBranch
                        operator: Equals
                        value: release
                      - key: sourceBranch
                        operator: Equals
                        value: bat
                      - key: changedFiles
                        operator: Regex
                        value: ^(apps\/${app_key}\/.*|environments\/preprod\/${app_key}\/.*)$
                    headerConditions: []
                    repoName: ${repo}
                    actions:
                      - Close
            inputSetRefs:
              - ${replace("${repo}-${app_key}-is", "-", "")}
  EOT
      }
    ]
  ])

}

module "feature_push_triggers" {
  source   = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-ecs-triggers?ref=develop"
  triggers = local.feature_push_triggers
  tags     = local.default_tags_list
}

module "dev_pr_triggers" {
  source   = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-ecs-triggers?ref=develop"
  triggers = local.dev_pr_triggers
  tags     = local.default_tags_list
}

module "bat_pr_triggers" {
  source   = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-ecs-triggers?ref=develop"
  triggers = local.bat_pr_triggers
  tags     = local.default_tags_list
}

module "release_pr_triggers" {
  source   = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-ecs-triggers?ref=develop"
  triggers = local.release_pr_triggers
  tags     = local.default_tags_list
}