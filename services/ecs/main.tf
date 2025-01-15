locals {
  # repository_names = [for repo in split("\n", file("./ecs-repositories.txt")) : repo if repo != ""]

  yaml_config = yamldecode(file("${path.module}/ecs-services.yaml"))

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

  # services = flatten([
  #   for repository_name in local.repository_names : {
  #     name       = "${repository_name}-ecs-svc"
  #     org_id     = var.org_id
  #     project_id = var.project_id
  #     identifier = "${replace(repository_name, "-", "")}ecssvc"
  #     yaml       = <<-EOT
  #       service:
  #         name: ${repository_name}-ecs-svc
  #         identifier:  ${replace(repository_name, "-", "")}ecssvc
  #         orgIdentifier: ${var.org_id}
  #         projectIdentifier: ${var.project_id}
  #         tags: {
  #                 "CostCode/AFC":"1904",
  #                 "Tower":"operation",
  #                 "DepartmentID":"1904",
  #                 "DepartmentName":"ops-digital",
  #                 "ProjectName":"Notification",
  #                 "Application":"ACNP",
  #                 "TechOwner":"Azeem Qaiser",
  #                 "BusinessOwner":"Pradeep Nishantha",
  #                 "Criticality":"Critical",
  #                 "Sensitivity":"High",
  #                 "ManagedBy":"Terraform",
  #                 "tf-repo-name":"ac-it-notifications-harness-resources-tf"
  #         }
  #         serviceDefinition:
  #           spec:
  #             manifests:
  #               - manifest:
  #                   identifier: taskdefinition
  #                   type: EcsTaskDefinition
  #                   spec:
  #                     store:
  #                       type: Github
  #                       spec:
  #                         connectorRef: <+input>
  #                         gitFetchType: Branch
  #                         paths:
  #                           - environments/<+serviceVariables.environment>/task-definition.json
  #                         repoName: <+input>
  #                         branch: <+input>
  #               - manifest:
  #                   identifier: servicedefinition
  #                   type: EcsServiceDefinition
  #                   spec:
  #                     store:
  #                       type: Github
  #                       spec:
  #                         connectorRef: <+input>
  #                         gitFetchType: Branch
  #                         paths:
  #                           - environments/<+serviceVariables.environment>/service-definition.json
  #                         repoName: <+input>
  #                         branch: <+input>
  #               - manifest:
  #                   identifier: memoryutilization
  #                   type: EcsScalingPolicyDefinition
  #                   spec:
  #                     store:
  #                       type: Github
  #                       spec:
  #                         connectorRef: <+input>
  #                         gitFetchType: Branch
  #                         paths:
  #                           - environments/<+serviceVariables.environment>/memory-utilization-scaling-policy.json
  #                         repoName: <+input>
  #                         branch: <+input>
  #               - manifest:
  #                   identifier: cpuutilization
  #                   type: EcsScalingPolicyDefinition
  #                   spec:
  #                     store:
  #                       type: Github
  #                       spec:
  #                         connectorRef: <+input>
  #                         gitFetchType: Branch
  #                         paths:
  #                           - environments/<+serviceVariables.environment>/cpu-utilization-scaling-policy.json
  #                         repoName: <+input>
  #                         branch: <+input>
  #               - manifest:
  #                   identifier: scalabletarget
  #                   type: EcsScalableTargetDefinition
  #                   spec:
  #                     store:
  #                       type: Github
  #                       spec:
  #                         connectorRef: <+input>
  #                         gitFetchType: Branch
  #                         paths:
  #                           - environments/<+serviceVariables.environment>/scalable-target.json
  #                         repoName: <+input>
  #                         branch: <+input>
  #             artifacts:
  #               primary:
  #                 primaryArtifactRef: <+input>
  #                 sources:
  #                   - spec:
  #                       connectorRef: <+input>
  #                       imagePath: <+input>
  #                       tag: <+input>
  #                       digest: ""
  #                       region: <+input>
  #                     identifier: artifact
  #                     type: Ecr
  #             variables:
  #               - name: environment
  #                 type: String
  #                 description: environment and application name
  #                 required: true
  #                 value: <+input>
  #           type: ECS
  #     EOT
  #   }
  # ])

  app_services = flatten([
    for repo, apps in local.yaml_config : [
      for app in apps : {
        name       = "${repo}-${app}-ecs-svc"
        org_id     = var.org_id
        project_id = var.project_id
        identifier = "${replace("${repo}-${app}-ecs-svc", "-", "")}"
        yaml       = <<-EOT
          service:
            name: ${repo}-${app}-ecs-svc
            identifier:  ${replace("${repo}-${app}-ecs-svc", "-", "")}
            orgIdentifier: ${var.org_id}
            projectIdentifier: ${var.project_id}
            tags: ${local.default_tags_map}
            serviceDefinition:
              spec:
                manifests:
                  - manifest:
                      identifier: taskdefinition
                      type: EcsTaskDefinition
                      spec:
                        store:
                          type: Github
                          spec:
                            connectorRef: <+input>
                            gitFetchType: Branch
                            paths:
                              - environments/<+serviceVariables.environment>/${app}/task-definition.json
                            repoName: <+input>
                            branch: <+input>
                  - manifest:
                      identifier: servicedefinition
                      type: EcsServiceDefinition
                      spec:
                        store:
                          type: Github
                          spec:
                            connectorRef: <+input>
                            gitFetchType: Branch
                            paths:
                              - environments/<+serviceVariables.environment>/${app}/service-definition.json
                            repoName: <+input>
                            branch: <+input>
                  - manifest:
                      identifier: memoryutilization
                      type: EcsScalingPolicyDefinition
                      spec:
                        store:
                          type: Github
                          spec:
                            connectorRef: <+input>
                            gitFetchType: Branch
                            paths:
                              - environments/<+serviceVariables.environment>/${app}/memory-utilization-scaling-policy.json
                            repoName: <+input>
                            branch: <+input>
                  - manifest:
                      identifier: cpuutilization
                      type: EcsScalingPolicyDefinition
                      spec:
                        store:
                          type: Github
                          spec:
                            connectorRef: <+input>
                            gitFetchType: Branch
                            paths:
                              - environments/<+serviceVariables.environment>/${app}/cpu-utilization-scaling-policy.json
                            repoName: <+input>
                            branch: <+input>
                  - manifest:
                      identifier: scalabletarget
                      type: EcsScalableTargetDefinition
                      spec:
                        store:
                          type: Github
                          spec:
                            connectorRef: <+input>
                            gitFetchType: Branch
                            paths:
                              - environments/<+serviceVariables.environment>/${app}/scalable-target.json
                            repoName: <+input>
                            branch: <+input>
                artifacts:
                  primary:
                    primaryArtifactRef: <+input>
                    sources:
                      - spec:
                          connectorRef: <+input>
                          imagePath: <+input>
                          tag: <+input>
                          digest: ""
                          region: <+input>
                        identifier: artifact
                        type: Ecr
                variables:
                  - name: environment
                    type: String
                    description: environment name
                    required: true
                    value: <+input>
              type: ECS
        EOT
      }
    ]
  ])
}

# module "services" {
#   source   = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-service?ref=develop"
#   services = local.services
#   tags     = local.default_tags_list
# }

module "app_services" {
  source   = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-ecs-service?ref=develop"
  services = local.app_services
  tags     = local.default_tags_list
}