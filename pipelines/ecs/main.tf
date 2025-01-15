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

  feature_pipeline_yaml = <<-EOT
    pipeline:
      name: ${var.feature_pipeline_name}
      identifier: ${replace(var.feature_pipeline_name, "-", "")}
      projectIdentifier: ${var.project_id}
      orgIdentifier: ${var.org_id}
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
      template:
        templateRef: featureecsdeploy
        versionLabel: "3"
        templateInputs:
          properties:
            ci:
              codebase:
                connectorRef: <+input>
                repoName: <+input>
                build: <+input>
          stages:
            - stage:
                identifier: buildandpushtoecr
                type: CI
                spec:
                  infrastructure:
                    type: KubernetesDirect
                    spec:
                      connectorRef: <+input>
                      namespace: <+input>
                      serviceAccountName: <+input>
                      os: <+input>
                  execution:
                    steps:
                      - step:
                          identifier: npmbuild
                          type: Run
                          spec:
                            connectorRef: <+input>
                            image: <+input>
                            resources:
                              limits:
                                memory: <+input>
                                cpu: <+input>
                          when:
                            condition: <+input>
                      - step:
                          identifier: rununittest
                          type: Run
                          spec:
                            connectorRef: <+input>
                            image: <+input>
                            command: <+input>
                            resources:
                              limits:
                                memory: <+input>
                                cpu: <+input>
                          when:
                            condition: <+input>
                      - step:
                          identifier: Sonarqube_Scan
                          type: Sonarqube
                          spec:
                            advanced:
                              args:
                                cli: <+input>
                            resources:
                              limits:
                                memory: <+input>
                                cpu: <+input>
                            tool:
                              project_key: <+input>
                          when:
                            condition: <+input>
                      - step:
                          identifier: BuildAndPushECR
                          type: BuildAndPushECR
                          spec:
                            connectorRef: <+input>
                            region: <+input>
                            account: <+input>
                            imageName: <+input>
                            caching: <+input>
                            dockerfile: <+input>
                            resources:
                              limits:
                                memory: <+input>
                                cpu: <+input>
            - stage:
                identifier: INT_approval
                type: Approval
                spec:
                  execution:
                    steps:
                      - step:
                          identifier: INT_Approval
                          type: HarnessApproval
                          spec:
                            approvers:
                              minimumCount: <+input>
                              userGroups: <+input>
            - stage:
                identifier: deploytoecs
                type: Deployment
                spec:
                  environment:
                    environmentRef: <+input>
                    environmentInputs: <+input>
                    serviceOverrideInputs: <+input>
                    infrastructureDefinitions: <+input>
                  service:
                    serviceRef: <+input>
                    serviceInputs: <+input>
                  execution:
                    steps:
                      - step:
                          identifier: ecsRollingDeploy
                          type: EcsRollingDeploy
                          timeout: <+input>
                      - step:
                          identifier: Verify
                          type: Verify
                          spec:
                            type: Auto
                            spec:
                              sensitivity: <+input>
                              duration: <+input>
                          timeout: <+input>
          variables:
            - name: environment
              type: String
              value: <+input>
            - name: application
              type: String
              value: <+input>
            - name: repository
              type: String
              value: <+input>
            - name: ecs_cluster
              type: String
              value: <+input>
            - name: ecr_repository
              type: String
              value: <+input>
            - name: region
              type: String
              value: <+input>
            - name: aws_account_id
              type: String
              value: <+input>
            - name: branch
              type: String
              value: <+input>
  EOT

  dev_pipeline_yaml = <<-EOT
    pipeline:
      name: ${var.dev_pipeline_name}
      identifier: ${replace(var.dev_pipeline_name, "-", "")}
      projectIdentifier: ${var.project_id}
      orgIdentifier: ${var.org_id}
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
      template:
        templateRef: devecsdeploy
        versionLabel: "3"
        templateInputs:
          properties:
            ci:
              codebase:
                connectorRef: <+input>
                repoName: <+input>
                build: <+input>
          stages:
            - stage:
                identifier: buildandpushtoecr
                type: CI
                spec:
                  infrastructure:
                    type: KubernetesDirect
                    spec:
                      connectorRef: <+input>
                      namespace: <+input>
                      serviceAccountName: <+input>
                      os: <+input>
                  execution:
                    steps:
                      - step:
                          identifier: npmbuild
                          type: Run
                          spec:
                            connectorRef: <+input>
                            image: <+input>
                            resources:
                              limits:
                                memory: <+input>
                                cpu: <+input>
                          when:
                            condition: <+input>
                      - step:
                          identifier: rununittest
                          type: Run
                          spec:
                            connectorRef: <+input>
                            image: <+input>
                            command: <+input>
                            resources:
                              limits:
                                memory: <+input>
                                cpu: <+input>
                          when:
                            condition: <+input>
                      - step:
                          identifier: Sonarqube_Scan
                          type: Sonarqube
                          spec:
                            advanced:
                              args:
                                cli: <+input>
                            resources:
                              limits:
                                memory: <+input>
                                cpu: <+input>
                            tool:
                              project_key: <+input>
                          when:
                            condition: <+input>
                      - step:
                          identifier: BuildAndPushECR
                          type: BuildAndPushECR
                          spec:
                            connectorRef: <+input>
                            region: <+input>
                            account: <+input>
                            imageName: <+input>
                            caching: <+input>
                            dockerfile: <+input>
                            resources:
                              limits:
                                memory: <+input>
                                cpu: <+input>
            - stage:
                identifier: INT_approval
                type: Approval
                spec:
                  execution:
                    steps:
                      - step:
                          identifier: INT_Approval
                          type: HarnessApproval
                          spec:
                            approvers:
                              minimumCount: <+input>
                              userGroups: <+input>
            - stage:
                identifier: deploytoecs
                type: Deployment
                spec:
                  environment:
                    environmentRef: <+input>
                    environmentInputs: <+input>
                    serviceOverrideInputs: <+input>
                    infrastructureDefinitions: <+input>
                  service:
                    serviceRef: <+input>
                    serviceInputs: <+input>
                  execution:
                    steps:
                      - step:
                          identifier: ecsRollingDeploy
                          type: EcsRollingDeploy
                          timeout: <+input>
                      - step:
                          identifier: Verify
                          type: Verify
                          spec:
                            type: Auto
                            spec:
                              sensitivity: <+input>
                              duration: <+input>
                          timeout: <+input>
          variables:
            - name: environment
              type: String
              value: <+input>
            - name: application
              type: String
              value: <+input>
            - name: repository
              type: String
              value: <+input>
            - name: ecs_cluster
              type: String
              value: <+input>
            - name: ecr_repository
              type: String
              value: <+input>
            - name: region
              type: String
              value: <+input>
            - name: aws_account_id
              type: String
              value: <+input>
            - name: branch
              type: String
              value: <+input>
  EOT

  bat_pipeline_yaml = <<-EOT
    pipeline:
      name: ${var.bat_pipeline_name}
      identifier: ${replace(var.bat_pipeline_name, "-", "")}
      projectIdentifier: ${var.project_id}
      orgIdentifier: ${var.org_id}
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
      template:
        templateRef: batecsdeploy
        versionLabel: "1"
        templateInputs:
          properties:
            ci:
              codebase:
                connectorRef: <+input>
                repoName: <+input>
                build: <+input>
          stages:
            - stage:
                identifier: buildandpushtoecr
                type: CI
                spec:
                  infrastructure:
                    type: KubernetesDirect
                    spec:
                      connectorRef: <+input>
                      namespace: <+input>
                      serviceAccountName: <+input>
                      os: <+input>
                  execution:
                    steps:
                      - step:
                          identifier: BuildAndPushECR
                          type: BuildAndPushECR
                          spec:
                            connectorRef: <+input>
                            region: <+input>
                            account: <+input>
                            imageName: <+input>
                            caching: <+input>
                            dockerfile: <+input>
                            resources:
                              limits:
                                memory: <+input>
                                cpu: <+input>
            - stage:
                identifier: BAT_Approval
                type: Approval
                spec:
                  execution:
                    steps:
                      - step:
                          identifier: BAT_Approval
                          type: HarnessApproval
                          spec:
                            approvers:
                              minimumCount: <+input>
                              userGroups: <+input>
            - stage:
                identifier: deploytoecs
                type: Deployment
                spec:
                  environment:
                    environmentRef: <+input>
                    environmentInputs: <+input>
                    serviceOverrideInputs: <+input>
                    infrastructureDefinitions: <+input>
                  service:
                    serviceRef: <+input>
                    serviceInputs: <+input>
                  execution:
                    steps:
                      - step:
                          identifier: ecsRollingDeploy
                          type: EcsRollingDeploy
                          timeout: <+input>
                      - step:
                          identifier: Verify
                          type: Verify
                          spec:
                            type: Auto
                            spec:
                              sensitivity: <+input>
                              duration: <+input>
                          timeout: <+input>
          variables:
            - name: environment
              type: String
              value: <+input>
            - name: application
              type: String
              value: <+input>
            - name: repository
              type: String
              value: <+input>
            - name: ecs_cluster
              type: String
              value: <+input>
            - name: ecr_repository
              type: String
              value: <+input>
            - name: region
              type: String
              value: <+input>
            - name: aws_account_id
              type: String
              value: <+input>
            - name: branch
              type: String
              value: <+input>
  EOT

  release_pipeline_yaml = <<-EOT
    pipeline:
      name: ${var.release_pipeline_name}
      identifier: ${replace(var.release_pipeline_name, "-", "")}
      projectIdentifier: ${var.project_id}
      orgIdentifier: ${var.org_id}
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
      template:
        templateRef: releaseecsdeploy
        versionLabel: "1"
        templateInputs:
          properties:
            ci:
              codebase:
                connectorRef: <+input>
                repoName: <+input>
                build: <+input>
          stages:
            - stage:
                identifier: buildandpushtoecr
                type: CI
                spec:
                  infrastructure:
                    type: KubernetesDirect
                    spec:
                      connectorRef: <+input>
                      namespace: <+input>
                      serviceAccountName: <+input>
                      os: <+input>
                  execution:
                    steps:
                      - step:
                          identifier: BuildAndPushECR
                          type: BuildAndPushECR
                          spec:
                            connectorRef: <+input>
                            region: <+input>
                            account: <+input>
                            imageName: <+input>
                            caching: <+input>
                            dockerfile: <+input>
                            resources:
                              limits:
                                memory: <+input>
                                cpu: <+input>
            - stage:
                identifier: PREPROD_Approval
                type: Approval
                spec:
                  execution:
                    steps:
                      - step:
                          identifier: PREPROD_Approval
                          type: HarnessApproval
                          spec:
                            approvers:
                              minimumCount: <+input>
                              userGroups: <+input>
            - stage:
                identifier: deploytoecs
                type: Deployment
                spec:
                  environment:
                    environmentRef: <+input>
                    environmentInputs: <+input>
                    serviceOverrideInputs: <+input>
                    infrastructureDefinitions: <+input>
                  service:
                    serviceRef: <+input>
                    serviceInputs: <+input>
                  execution:
                    steps:
                      - step:
                          identifier: ecsRollingDeploy
                          type: EcsRollingDeploy
                          timeout: <+input>
                      - step:
                          identifier: Verify
                          type: Verify
                          spec:
                            type: Auto
                            spec:
                              sensitivity: <+input>
                              duration: <+input>
                          timeout: <+input>
          variables:
            - name: environment
              type: String
              value: <+input>
            - name: application
              type: String
              value: <+input>
            - name: repository
              type: String
              value: <+input>
            - name: ecs_cluster
              type: String
              value: <+input>
            - name: ecr_repository
              type: String
              value: <+input>
            - name: region
              type: String
              value: <+input>
            - name: aws_account_id
              type: String
              value: <+input>
            - name: branch
              type: String
              value: <+input>
  EOT

  main_pipeline_yaml = <<-EOT
    pipeline:
      name: ${var.main_pipeline_name}
      identifier: ${replace(var.main_pipeline_name, "-", "")}
      projectIdentifier: ${var.project_id}
      orgIdentifier: ${var.org_id}
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
      template:
        templateRef: mainecsdeploy
        versionLabel: "1"
        templateInputs:
          properties:
            ci:
              codebase:
                connectorRef: <+input>
                repoName: <+input>
                build: <+input>
          stages:
            - stage:
                identifier: PROD_Approval
                type: Approval
                spec:
                  execution:
                    steps:
                      - step:
                          identifier: PROD_Approval
                          type: HarnessApproval
                          spec:
                            approvers:
                              minimumCount: <+input>
                              userGroups: <+input>
            - stage:
                identifier: ServiceNow_Approval
                type: Approval
                spec:
                  execution:
                    steps:
                      - step:
                          identifier: Approval_for_PROD
                          type: ServiceNowApproval
                          spec:
                            ticketNumber: <+input>
            - stage:
                identifier: buildandpushtoecr
                type: CI
                spec:
                  infrastructure:
                    type: KubernetesDirect
                    spec:
                      connectorRef: <+input>
                      namespace: <+input>
                      serviceAccountName: <+input>
                      os: <+input>
                  execution:
                    steps:
                      - step:
                          identifier: BuildAndPushECR
                          type: BuildAndPushECR
                          spec:
                            connectorRef: <+input>
                            region: <+input>
                            account: <+input>
                            imageName: <+input>
                            caching: <+input>
                            dockerfile: <+input>
                            resources:
                              limits:
                                memory: <+input>
                                cpu: <+input>
            - stage:
                identifier: deploytoecs
                type: Deployment
                spec:
                  environment:
                    environmentRef: <+input>
                    environmentInputs: <+input>
                    serviceOverrideInputs: <+input>
                    infrastructureDefinitions: <+input>
                  service:
                    serviceRef: <+input>
                    serviceInputs: <+input>
                  execution:
                    steps:
                      - step:
                          identifier: ecsRollingDeploy
                          type: EcsRollingDeploy
                          timeout: <+input>
                      - step:
                          identifier: Verify
                          type: Verify
                          spec:
                            type: Auto
                            spec:
                              sensitivity: <+input>
                              duration: <+input>
                          timeout: <+input>
          variables:
            - name: environment
              type: String
              value: <+input>
            - name: application
              type: String
              value: <+input>
            - name: repository
              type: String
              value: <+input>
            - name: ecs_cluster
              type: String
              value: <+input>
            - name: ecr_repository
              type: String
              value: <+input>
            - name: region
              type: String
              value: <+input>
            - name: aws_account_id
              type: String
              value: <+input>
            - name: branch
              type: String
              value: <+input>
  EOT

}

module "feature_pipeline" {
  source     = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-pipelines?ref=develop"
  name       = var.feature_pipeline_name
  identifier = replace(var.feature_pipeline_name, "-", "")
  org_id     = var.org_id
  project_id = var.project_id
  yaml       = local.feature_pipeline_yaml
  tags       = local.default_tags_list
}

module "dev_pipeline" {
  source     = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-pipelines?ref=develop"
  name       = var.dev_pipeline_name
  identifier = replace(var.dev_pipeline_name, "-", "")
  org_id     = var.org_id
  project_id = var.project_id
  yaml       = local.dev_pipeline_yaml
  tags       = local.default_tags_list
}

module "bat_pipeline" {
  source     = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-pipelines?ref=develop"
  name       = var.bat_pipeline_name
  identifier = replace(var.bat_pipeline_name, "-", "")
  org_id     = var.org_id
  project_id = var.project_id
  yaml       = local.bat_pipeline_yaml
  tags       = local.default_tags_list
}

module "release_pipeline" {
  source     = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-pipelines?ref=develop"
  name       = var.release_pipeline_name
  identifier = replace(var.release_pipeline_name, "-", "")
  org_id     = var.org_id
  project_id = var.project_id
  yaml       = local.release_pipeline_yaml
  tags       = local.default_tags_list
}

module "main_pipeline" {
  source     = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-pipelines?ref=develop"
  name       = var.main_pipeline_name
  identifier = replace(var.main_pipeline_name, "-", "")
  org_id     = var.org_id
  project_id = var.project_id
  yaml       = local.main_pipeline_yaml
  tags       = local.default_tags_list
}