locals {
  envs             = var.envs
  account_names    = var.account_names
  env_account_map  = zipmap(local.envs, local.account_names)
  repository_names = [for repo in split("\n", file("./repo-list.txt")) : repo if repo != ""]

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

  # yaml_config = yamldecode(file("${path.module}/acnp-crew-ops-dof-int.yaml"))

  # applications_int = flatten([
  #   for repo, apps in local.yaml_config : [
  #     for app_key, app_value in apps : {
  #       repository     = repo
  #       application    = app_key
  #       name           = app_value[0].name
  #       aws_account_id = app_value[0].aws_account_id
  #       environment    = app_value[0].environment
  #       region         = app_value[0].region
  #       ecr_repository = app_value[0].ecr_repository
  #       ecs_cluster    = app_value[0].ecs_cluster
  #     }
  #   ]
  # ])

  # feature_inputsets = flatten([
  #   for repo, apps in local.yaml_config : [
  #     for app_key, app_value in apps : {
  #       name        = "${repo}-${app_key}-is"
  #       identifier  = "${replace("${repo}-${app_key}-is", "-", "")}"
  #       org_id      = var.org_id
  #       project_id  = var.project_id
  #       pipeline_id = "${replace(var.feature_pipeline_name, "-", "")}"
  #       yaml        = <<-EOT
  #         inputSet:
  #           name: "${repo}-${app_key}-is"
  #           identifier: "${replace("${repo}-${app_key}-is", "-", "")}"
  #           orgIdentifier: ${var.org_id}
  #           projectIdentifier: ${var.project_id}
  #           tags: ${local.default_tags_map}
  #           pipeline:
  #             identifier: "${replace(var.feature_pipeline_name, "-", "")}"
  #             template:
  #               templateInputs:
  #                 properties:
  #                   ci:
  #                     codebase:
  #                       connectorRef: ${var.repository_connector}
  #                       repoName: <+pipeline.variables.repository>
  #                       build:
  #                         type: branch
  #                         spec:
  #                           branch: <+trigger.targetBranch>
  #                 stages:
  #                   - stage:
  #                       identifier: buildandpushtoecr
  #                       type: CI
  #                       spec:
  #                         infrastructure:
  #                           type: KubernetesDirect
  #                           spec:
  #                             connectorRef: org.${var.kubernetes_delegate_connector_nonprod}
  #                             namespace: ${var.kubernetes_delegate_connector_ns_nonprod}
  #                             serviceAccountName: ${var.kubernetes_delegate_connector_sa_nonprod}
  #                             os: Linux
  #                         execution:
  #                           steps:
  #                             - step:
  #                                 identifier: BuildAndPushECR
  #                                 type: BuildAndPushECR
  #                                 spec:
  #                                   connectorRef: ${var.provider_connector_int}
  #                                   region:  <+pipeline.variables.region>
  #                                   account: <+pipeline.variables.aws_account_id>
  #                                   imageName: <+pipeline.variables.ecr_repository>
  #                                   caching: true
  #                                   dockerfile: apps/${app_key}/Dockerfile
  #                                   resources:
  #                                     limits:
  #                                       memory: ${app_value[0].limit_memory}
  #                                       cpu: "${app_value[0].limit_cpu}"
  #                   - stage:
  #                       identifier: INT_approval
  #                       type: Approval
  #                       spec:
  #                         execution:
  #                           steps:
  #                             - step:
  #                                 identifier: INT_Approval
  #                                 type: HarnessApproval
  #                                 spec:
  #                                   approvers:
  #                                     minimumCount: 1
  #                                     userGroups:
  #                                       - ${var.developers_user_group}
  #                                       - ${var.devops_user_group}
  #                   - stage:
  #                       identifier: deploytoecs
  #                       type: Deployment
  #                       spec:
  #                         environment:
  #                           environmentRef: ${app_value[0].environment}
  #                           infrastructureDefinitions:
  #                             - identifier: ${replace(local.env_account_map["int"], "-", "")}ecs
  #                               inputs:
  #                                 identifier: ${replace(local.env_account_map["int"], "-", "")}ecs
  #                                 type: ECS
  #                                 spec:
  #                                   connectorRef: ${var.provider_connector_int}
  #                                   region: <+pipeline.variables.region>
  #                                   cluster: <+pipeline.variables.ecs_cluster>
  #                         service:
  #                           serviceRef: "${replace("${repo}-${app_key}-ecs-svc", "-", "")}"
  #                           serviceInputs:
  #                             serviceDefinition:
  #                               type: ECS
  #                               spec:
  #                                 manifests:
  #                                   - manifest:
  #                                       identifier: taskdefinition
  #                                       type: EcsTaskDefinition
  #                                       spec:
  #                                         store:
  #                                           type: Github
  #                                           spec:
  #                                             connectorRef: ${var.repository_connector}
  #                                             repoName: <+pipeline.variables.repository>
  #                                             branch: <+trigger.targetBranch>
  #                                   - manifest:
  #                                       identifier: servicedefinition
  #                                       type: EcsServiceDefinition
  #                                       spec:
  #                                         store:
  #                                           type: Github
  #                                           spec:
  #                                             connectorRef: ${var.repository_connector}
  #                                             repoName: <+pipeline.variables.repository>
  #                                             branch: <+trigger.targetBranch>
  #                                   - manifest:
  #                                       identifier: memoryutilization
  #                                       type: EcsScalingPolicyDefinition
  #                                       spec:
  #                                         store:
  #                                           type: Github
  #                                           spec:
  #                                             connectorRef: ${var.repository_connector}
  #                                             repoName: <+pipeline.variables.repository>
  #                                             branch: <+trigger.targetBranch>
  #                                   - manifest:
  #                                       identifier: cpuutilization
  #                                       type: EcsScalingPolicyDefinition
  #                                       spec:
  #                                         store:
  #                                           type: Github
  #                                           spec:
  #                                             connectorRef: ${var.repository_connector}
  #                                             repoName: <+pipeline.variables.repository>
  #                                             branch: <+trigger.targetBranch>
  #                                   - manifest:
  #                                       identifier: scalabletarget
  #                                       type: EcsScalableTargetDefinition
  #                                       spec:
  #                                         store:
  #                                           type: Github
  #                                           spec:
  #                                             connectorRef: ${var.repository_connector}
  #                                             repoName: <+pipeline.variables.repository>
  #                                             branch: <+trigger.targetBranch>
  #                                 artifacts:
  #                                   primary:
  #                                     primaryArtifactRef: artifact
  #                                     sources:
  #                                       - identifier: artifact
  #                                         type: Ecr
  #                                         spec:
  #                                           connectorRef: ${var.provider_connector_int}
  #                                           imagePath: <+pipeline.variables.ecr_repository>
  #                                           tag: <+pipeline.sequenceId>
  #                                           region: <+pipeline.variables.region>
  #                                 variables:
  #                                   - name: environment
  #                                     type: String
  #                                     value: <+pipeline.variables.environment>
  #                                     description: environment name
  #                                     required: true
  #                         execution:
  #                           steps:
  #                             - step:
  #                                 identifier: ecsRollingDeploy
  #                                 type: EcsRollingDeploy
  #                                 timeout: 10m
  #                 variables:
  #                   - name: environment
  #                     type: String
  #                     value: ${app_value[0].environment}
  #                   - name: application
  #                     type: String
  #                     value: ${app_key}
  #                   - name: repository
  #                     type: String
  #                     value: ${repo}
  #                   - name: ecs_cluster
  #                     type: String
  #                     value: ${app_value[0].ecs_cluster}
  #                   - name: ecr_repository
  #                     type: String
  #                     value: ${app_value[0].ecr_repository}
  #                   - name: region
  #                     type: String
  #                     value: ${app_value[0].region}
  #                   - name: aws_account_id
  #                     type: String
  #                     value: "${app_value[0].aws_account_id}"
  #       EOT
  #     }
  #   ]
  # ])

  # dev_inputsets = flatten([
  #   for repo, apps in local.yaml_config : [
  #     for app_key, app_value in apps : {
  #       name        = "${repo}-${app_key}-is"
  #       identifier  = "${replace("${repo}-${app_key}-is", "-", "")}"
  #       org_id      = var.org_id
  #       project_id  = var.project_id
  #       pipeline_id = "${replace(var.dev_pipeline_name, "-", "")}"
  #       yaml        = <<-EOT
  #         inputSet:
  #           name: "${repo}-${app_key}-is"
  #           identifier: "${replace("${repo}-${app_key}-is", "-", "")}"
  #           orgIdentifier: ${var.org_id}
  #           projectIdentifier: ${var.project_id}
  #           tags: ${local.default_tags_map}
  #           pipeline:
  #             identifier: "${replace(var.dev_pipeline_name, "-", "")}"
  #             template:
  #               templateInputs:
  #                 properties:
  #                   ci:
  #                     codebase:
  #                       connectorRef: ${var.repository_connector}
  #                       repoName: <+pipeline.variables.repository>
  #                       build:
  #                         type: branch
  #                         spec:
  #                           branch: <+trigger.targetBranch>
  #                 stages:
  #                   - stage:
  #                       identifier: buildandpushtoecr
  #                       type: CI
  #                       spec:
  #                         infrastructure:
  #                           type: KubernetesDirect
  #                           spec:
  #                             connectorRef: org.${var.kubernetes_delegate_connector_nonprod}
  #                             namespace: ${var.kubernetes_delegate_connector_ns_nonprod}
  #                             serviceAccountName: ${var.kubernetes_delegate_connector_sa_nonprod}
  #                             os: Linux
  #                         execution:
  #                           steps:
  #                             - step:
  #                                 identifier: BuildAndPushECR
  #                                 type: BuildAndPushECR
  #                                 spec:
  #                                   connectorRef: ${var.provider_connector_int}
  #                                   region:  <+pipeline.variables.region>
  #                                   account: <+pipeline.variables.aws_account_id>
  #                                   imageName: <+pipeline.variables.ecr_repository>
  #                                   caching: true
  #                                   dockerfile: apps/${app_key}/Dockerfile
  #                                   resources:
  #                                     limits:
  #                                       memory: ${app_value[0].limit_memory}
  #                                       cpu: "${app_value[0].limit_cpu}"
  #                   - stage:
  #                       identifier: INT_approval
  #                       type: Approval
  #                       spec:
  #                         execution:
  #                           steps:
  #                             - step:
  #                                 identifier: INT_Approval
  #                                 type: HarnessApproval
  #                                 spec:
  #                                   approvers:
  #                                     minimumCount: 1
  #                                     userGroups:
  #                                       - ${var.developers_user_group}
  #                                       - ${var.devops_user_group}
  #                   - stage:
  #                       identifier: deploytoecs
  #                       type: Deployment
  #                       spec:
  #                         environment:
  #                           environmentRef: ${app_value[0].environment}
  #                           infrastructureDefinitions:
  #                             - identifier: ${replace(local.env_account_map["int"], "-", "")}ecs
  #                               inputs:
  #                                 identifier: ${replace(local.env_account_map["int"], "-", "")}ecs
  #                                 type: ECS
  #                                 spec:
  #                                   connectorRef: ${var.provider_connector_int}
  #                                   region: <+pipeline.variables.region>
  #                                   cluster: <+pipeline.variables.ecs_cluster>
  #                         service:
  #                           serviceRef: "${replace("${repo}-${app_key}-ecs-svc", "-", "")}"
  #                           serviceInputs:
  #                             serviceDefinition:
  #                               type: ECS
  #                               spec:
  #                                 manifests:
  #                                   - manifest:
  #                                       identifier: taskdefinition
  #                                       type: EcsTaskDefinition
  #                                       spec:
  #                                         store:
  #                                           type: Github
  #                                           spec:
  #                                             connectorRef: ${var.repository_connector}
  #                                             repoName: <+pipeline.variables.repository>
  #                                             branch: <+trigger.targetBranch>
  #                                   - manifest:
  #                                       identifier: servicedefinition
  #                                       type: EcsServiceDefinition
  #                                       spec:
  #                                         store:
  #                                           type: Github
  #                                           spec:
  #                                             connectorRef: ${var.repository_connector}
  #                                             repoName: <+pipeline.variables.repository>
  #                                             branch: <+trigger.targetBranch>
  #                                   - manifest:
  #                                       identifier: memoryutilization
  #                                       type: EcsScalingPolicyDefinition
  #                                       spec:
  #                                         store:
  #                                           type: Github
  #                                           spec:
  #                                             connectorRef: ${var.repository_connector}
  #                                             repoName: <+pipeline.variables.repository>
  #                                             branch: <+trigger.targetBranch>
  #                                   - manifest:
  #                                       identifier: cpuutilization
  #                                       type: EcsScalingPolicyDefinition
  #                                       spec:
  #                                         store:
  #                                           type: Github
  #                                           spec:
  #                                             connectorRef: ${var.repository_connector}
  #                                             repoName: <+pipeline.variables.repository>
  #                                             branch: <+trigger.targetBranch>
  #                                   - manifest:
  #                                       identifier: scalabletarget
  #                                       type: EcsScalableTargetDefinition
  #                                       spec:
  #                                         store:
  #                                           type: Github
  #                                           spec:
  #                                             connectorRef: ${var.repository_connector}
  #                                             repoName: <+pipeline.variables.repository>
  #                                             branch: <+trigger.targetBranch>
  #                                 artifacts:
  #                                   primary:
  #                                     primaryArtifactRef: artifact
  #                                     sources:
  #                                       - identifier: artifact
  #                                         type: Ecr
  #                                         spec:
  #                                           connectorRef: ${var.provider_connector_int}
  #                                           imagePath: <+pipeline.variables.ecr_repository>
  #                                           tag: <+pipeline.sequenceId>
  #                                           region: <+pipeline.variables.region>
  #                                 variables:
  #                                   - name: environment
  #                                     type: String
  #                                     value: <+pipeline.variables.environment>
  #                                     description: environment name
  #                                     required: true
  #                         execution:
  #                           steps:
  #                             - step:
  #                                 identifier: ecsRollingDeploy
  #                                 type: EcsRollingDeploy
  #                                 timeout: 10m
  #                 variables:
  #                   - name: environment
  #                     type: String
  #                     value: ${app_value[0].environment}
  #                   - name: application
  #                     type: String
  #                     value: ${app_key}
  #                   - name: repository
  #                     type: String
  #                     value: ${repo}
  #                   - name: ecs_cluster
  #                     type: String
  #                     value: ${app_value[0].ecs_cluster}
  #                   - name: ecr_repository
  #                     type: String
  #                     value: ${app_value[0].ecr_repository}
  #                   - name: region
  #                     type: String
  #                     value: ${app_value[0].region}
  #                   - name: aws_account_id
  #                     type: String
  #                     value: "${app_value[0].aws_account_id}"
  #       EOT
  #     }
  #   ]
  # ])

  dev_input_sets = flatten([
    for repository_name in local.repository_names : {
      name        = repository_name
      org_id      = var.org_id
      project_id  = var.project_id
      identifier  = "${replace(repository_name, "-", "")}"
      pipeline_id = var.dev_pipeline_id
      yaml        = <<-EOT
        inputSet:
          name: ${repository_name}
          tags: {}
          identifier: ${replace(repository_name, "-", "")}
          orgIdentifier: ${var.org_id}
          projectIdentifier: ${var.project_id}
          pipeline:
            identifier: devcdkdeploy
            template:
              templateInputs:
                stages:
                  - stage:
                      identifier: cdkdeployint
                      type: Custom
                      spec:
                        environment:
                          environmentRef: int
                          infrastructureDefinitions:
                            - identifier: awsacnotificationintconnector
                        execution:
                          steps:
                            - stepGroup:
                                identifier: CDK_Diff
                                steps:
                                  - step:
                                      identifier: Git_Clone
                                      type: GitClone
                                      spec:
                                        connectorRef: org.acitdevelopmentgithubharnessconnectorssh
                                        repoName: acnp-crew-ops-dof-infra
                                        resources:
                                          limits:
                                            memory: 1G
                                            cpu: "1"
                                        build:
                                          type: branch
                                          spec:
                                            branch: feature/harness-cdk
                                  - step:
                                      identifier: AWS_CDK_Diff
                                      type: Run
                                      spec:
                                        connectorRef: account.harnessImage
                                        image: node:18-alpine
                                        envVariables:
                                          CDK_DEPLOYMENT_IAM_ROLE: arn:aws:iam::148761674185:role/harness-notification-platform-int-deployment-role
                                        resources:
                                          limits:
                                            memory: 4G
                                            cpu: "2"
                                stepGroupInfra:
                                  type: KubernetesDirect
                                  spec:
                                    connectorRef: org.operations_eks_connector_nonprod
                                    namespace: harness-operations-nonprod-ng
                                    serviceAccountName: operations-delegate-nonprod-sa
                            - step:
                                identifier: CDK_Approval
                                type: HarnessApproval
                                spec:
                                  approvers:
                                    userGroups:
                                      - account.acitnotificationsdevelopers
                                      - account.acdevops
                                    minimumCount: 1
                            - stepGroup:
                                identifier: CDK_Deploy
                                steps:
                                  - step:
                                      identifier: Git_Clone
                                      type: GitClone
                                      spec:
                                        connectorRef: org.acitdevelopmentgithubharnessconnectorssh
                                        repoName: acnp-crew-ops-dof-infra
                                        resources:
                                          limits:
                                            memory: 1G
                                            cpu: "1"
                                        build:
                                          type: branch
                                          spec:
                                            branch: feature/harness-cdk
                                  - step:
                                      identifier: AWS_CDK_Application_Deploy
                                      type: Run
                                      spec:
                                        connectorRef: account.harnessImage
                                        image: node:18-alpine
                                        envVariables:
                                          CDK_DEPLOYMENT_IAM_ROLE: arn:aws:iam::148761674185:role/harness-notification-platform-int-deployment-role
                                        resources:
                                          limits:
                                            memory: 4G
                                            cpu: "2"
                                stepGroupInfra:
                                  type: KubernetesDirect
                                  spec:
                                    connectorRef: org.operations_eks_connector_nonprod
                                    namespace: harness-operations-nonprod-ng
                                    serviceAccountName: operations-delegate-nonprod-sa
              EOT
    }
  ])

}

module "dev_inputsets" {
  source     = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-cicd-inputsets?ref=develop"
  input_sets = local.dev_inputsets
  tags       = local.default_tags_list
}