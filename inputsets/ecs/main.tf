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

  yaml_config_dev     = yamldecode(file("${path.module}/input-sets-dev.yaml"))
  yaml_config_bat     = yamldecode(file("${path.module}/input-sets-bat.yaml"))
  yaml_config_release = yamldecode(file("${path.module}/input-sets-release.yaml"))
  yaml_config_main    = yamldecode(file("${path.module}/input-sets-main.yaml"))

  # applications_int = flatten([
  #   for repo, apps in local.yaml_config_dev : [
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

  feature_inputsets = flatten([
    for repo, apps in local.yaml_config_dev : [
      for app_key, app_value in apps : {
        name        = "${repo}-${app_key}-is"
        identifier  = "${replace("${repo}-${app_key}-is", "-", "")}"
        org_id      = var.org_id
        project_id  = var.project_id
        pipeline_id = "${replace(var.feature_pipeline_name, "-", "")}"
        yaml        = <<-EOT
          inputSet:
            name: ${repo}-${app_key}-is
            identifier: ${replace("${repo}-${app_key}-is", "-", "")}
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
            pipeline:
              identifier: ${replace(var.feature_pipeline_name, "-", "")}
              template:
                templateInputs:
                  properties:
                    ci:
                      codebase:
                        connectorRef: ${var.repository_connector}
                        repoName: <+pipeline.variables.repository>
                        build:
                          type: branch
                          spec:
                            branch: <+pipeline.variables.branch>
                  stages:
                    - stage:
                        identifier: buildandpushtoecr
                        type: CI
                        spec:
                          infrastructure:
                            type: KubernetesDirect
                            spec:
                              connectorRef: org.${var.kubernetes_delegate_connector_nonprod}
                              namespace: ${var.kubernetes_delegate_connector_ns_nonprod}
                              serviceAccountName: ${var.kubernetes_delegate_connector_sa_nonprod}
                              os: Linux
                          execution:
                            steps:
                              - step:
                                  identifier: npmbuild
                                  type: Run
                                  spec:
                                    connectorRef: account.harnessImage
                                    image: atlassian/default-image:4
                                    resources:
                                      limits:
                                        memory: ${app_value[0].limit_memory}
                                        cpu: "${app_value[0].limit_cpu}"
                                  when:
                                    condition: "true"
                              - step:
                                  identifier: rununittest
                                  type: Run
                                  spec:
                                    connectorRef: account.harnessImage
                                    image: atlassian/default-image:4
                                    command: |-
                                      #Set HOME path as harness
                                      export HOME=/harness
                                      apt update -y
                                      #Run unit test cases
                                      npm install -g jest
                                      npm install jest-junit
                                      #Custom packages
                                      folders=$(find . -type d -name "node_modules" -prune -o -type f -name "package.json" -print | xargs dirname)
                                      for dir in $folders; do
                                        echo "Installing npm packages in $dir"
                                        (
                                          cd "$dir" || { echo "Failed to enter directory $dir"; exit 1; }
                                          npm i
                                        )
                                      done
                                      #Run the unit test cases
                                      npm run test
                                    resources:
                                      limits:
                                        memory: ${app_value[0].limit_memory}
                                        cpu: "${app_value[0].limit_cpu}"
                                  when:
                                    condition: "true"
                              - step:
                                  identifier: Sonarqube_Scan
                                  type: Sonarqube
                                  spec:
                                    advanced:
                                      args:
                                        cli: "-Dsonar.projectName=${repo}"
                                    resources:
                                      limits:
                                        memory: ${app_value[0].limit_memory}
                                        cpu: "${app_value[0].limit_cpu}"
                                    tool:
                                      project_key: <+variable.org.portfolio_name>_<+variable.sonarqube_project_key>_${repo}
                                  when:
                                    condition: "true"
                              - step:
                                  identifier: BuildAndPushECR
                                  type: BuildAndPushECR
                                  spec:
                                    connectorRef: ${var.provider_connector_int}
                                    region: <+pipeline.variables.region>
                                    account: <+pipeline.variables.aws_account_id>
                                    imageName: <+pipeline.variables.ecr_repository>
                                    caching: true
                                    dockerfile: apps/${app_key}/Dockerfile
                                    resources:
                                      limits:
                                        memory: ${app_value[0].limit_memory}
                                        cpu: "${app_value[0].limit_cpu}"
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
                                      minimumCount: 1
                                      userGroups:
                                        - ${var.developers_user_group}
                                        - ${var.devops_user_group}
                    - stage:
                        identifier: deploytoecs
                        type: Deployment
                        spec:
                          environment:
                            environmentRef: ${app_value[0].environment}
                            infrastructureDefinitions:
                              - identifier: ${replace(local.env_account_map["int"], "-", "")}ecs
                                inputs:
                                  identifier: ${replace(local.env_account_map["int"], "-", "")}ecs
                                  type: ECS
                                  spec:
                                    connectorRef: ${var.provider_connector_int}
                                    region: <+pipeline.variables.region>
                                    cluster: <+pipeline.variables.ecs_cluster>
                          service:
                            serviceRef: ${replace("${repo}-${app_key}-ecs-svc", "-", "")}
                            serviceInputs:
                              serviceDefinition:
                                type: ECS
                                spec:
                                  manifests:
                                    - manifest:
                                        identifier: taskdefinition
                                        type: EcsTaskDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: servicedefinition
                                        type: EcsServiceDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: memoryutilization
                                        type: EcsScalingPolicyDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: cpuutilization
                                        type: EcsScalingPolicyDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: scalabletarget
                                        type: EcsScalableTargetDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                  artifacts:
                                    primary:
                                      primaryArtifactRef: artifact
                                      sources:
                                        - identifier: artifact
                                          type: Ecr
                                          spec:
                                            connectorRef: ${var.provider_connector_int}
                                            imagePath: <+pipeline.variables.ecr_repository>
                                            tag: <+pipeline.sequenceId>
                                            region: <+pipeline.variables.region>
                                  variables:
                                    - name: environment
                                      type: String
                                      description: environment name
                                      value: <+pipeline.variables.environment>
                                      required: true
                          execution:
                            steps:
                              - step:
                                  identifier: ecsRollingDeploy
                                  type: EcsRollingDeploy
                                  timeout: 10m
                              - step:
                                  identifier: Verify
                                  type: Verify
                                  spec:
                                    type: Auto
                                    spec:
                                      sensitivity: LOW
                                      duration: 10m
                                  timeout: 1h
                  variables:
                    - name: environment
                      type: String
                      value: ${app_value[0].environment}
                    - name: application
                      type: String
                      value: ${app_key}
                    - name: repository
                      type: String
                      value: ${repo}
                    - name: ecs_cluster
                      type: String
                      value: ${app_value[0].ecs_cluster}
                    - name: ecr_repository
                      type: String
                      value: ${app_value[0].ecr_repository}
                    - name: region
                      type: String
                      value: ${app_value[0].region}
                    - name: aws_account_id
                      type: String
                      value: "${app_value[0].aws_account_id}"
                    - name: branch
                      type: String
                      value: <+trigger.targetBranch>
        EOT
      }
    ]
  ])

  dev_inputsets = flatten([
    for repo, apps in local.yaml_config_dev : [
      for app_key, app_value in apps : {
        name        = "${repo}-${app_key}-is"
        identifier  = "${replace("${repo}-${app_key}-is", "-", "")}"
        org_id      = var.org_id
        project_id  = var.project_id
        pipeline_id = "${replace(var.dev_pipeline_name, "-", "")}"
        yaml        = <<-EOT
          inputSet:
            name: ${repo}-${app_key}-is
            identifier: ${replace("${repo}-${app_key}-is", "-", "")}
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
            pipeline:
              identifier: ${replace(var.dev_pipeline_name, "-", "")}
              template:
                templateInputs:
                  properties:
                    ci:
                      codebase:
                        connectorRef: ${var.repository_connector}
                        repoName: <+pipeline.variables.repository>
                        build:
                          type: branch
                          spec:
                            branch: <+pipeline.variables.branch>
                  stages:
                    - stage:
                        identifier: buildandpushtoecr
                        type: CI
                        spec:
                          infrastructure:
                            type: KubernetesDirect
                            spec:
                              connectorRef: org.${var.kubernetes_delegate_connector_nonprod}
                              namespace: ${var.kubernetes_delegate_connector_ns_nonprod}
                              serviceAccountName: ${var.kubernetes_delegate_connector_sa_nonprod}
                              os: Linux
                          execution:
                            steps:
                              - step:
                                  identifier: npmbuild
                                  type: Run
                                  spec:
                                    connectorRef: account.harnessImage
                                    image: atlassian/default-image:4
                                    resources:
                                      limits:
                                        memory: ${app_value[0].limit_memory}
                                        cpu: "${app_value[0].limit_cpu}"
                                  when:
                                    condition: "true"
                              - step:
                                  identifier: rununittest
                                  type: Run
                                  spec:
                                    connectorRef: account.harnessImage
                                    image: atlassian/default-image:4
                                    command: |-
                                      #Set HOME path as harness
                                      export HOME=/harness
                                      apt update -y
                                      #Run unit test cases
                                      npm install -g jest
                                      npm install jest-junit
                                      #Custom packages
                                      folders=$(find . -type d -name "node_modules" -prune -o -type f -name "package.json" -print | xargs dirname)
                                      for dir in $folders; do
                                        echo "Installing npm packages in $dir"
                                        (
                                          cd "$dir" || { echo "Failed to enter directory $dir"; exit 1; }
                                          npm i
                                        )
                                      done
                                      #Run the unit test cases
                                      npm run test
                                    resources:
                                      limits:
                                        memory: ${app_value[0].limit_memory}
                                        cpu: "${app_value[0].limit_cpu}"
                                  when:
                                    condition: "true"
                              - step:
                                  identifier: Sonarqube_Scan
                                  type: Sonarqube
                                  spec:
                                    advanced:
                                      args:
                                        cli: "-Dsonar.projectName=${repo}"
                                    resources:
                                      limits:
                                        memory: ${app_value[0].limit_memory}
                                        cpu: "${app_value[0].limit_cpu}"
                                    tool:
                                      project_key: <+variable.org.portfolio_name>_<+variable.sonarqube_project_key>_${repo}
                                  when:
                                    condition: "true"
                              - step:
                                  identifier: BuildAndPushECR
                                  type: BuildAndPushECR
                                  spec:
                                    connectorRef: ${var.provider_connector_int}
                                    region: <+pipeline.variables.region>
                                    account: <+pipeline.variables.aws_account_id>
                                    imageName: <+pipeline.variables.ecr_repository>
                                    caching: true
                                    dockerfile: apps/${app_key}/Dockerfile
                                    resources:
                                      limits:
                                        memory: ${app_value[0].limit_memory}
                                        cpu: "${app_value[0].limit_cpu}"
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
                                      minimumCount: 1
                                      userGroups:
                                        - ${var.developers_user_group}
                                        - ${var.devops_user_group}
                    - stage:
                        identifier: deploytoecs
                        type: Deployment
                        spec:
                          environment:
                            environmentRef: ${app_value[0].environment}
                            infrastructureDefinitions:
                              - identifier: ${replace(local.env_account_map["int"], "-", "")}ecs
                                inputs:
                                  identifier: ${replace(local.env_account_map["int"], "-", "")}ecs
                                  type: ECS
                                  spec:
                                    connectorRef: ${var.provider_connector_int}
                                    region: <+pipeline.variables.region>
                                    cluster: <+pipeline.variables.ecs_cluster>
                          service:
                            serviceRef: ${replace("${repo}-${app_key}-ecs-svc", "-", "")}
                            serviceInputs:
                              serviceDefinition:
                                type: ECS
                                spec:
                                  manifests:
                                    - manifest:
                                        identifier: taskdefinition
                                        type: EcsTaskDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: servicedefinition
                                        type: EcsServiceDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: memoryutilization
                                        type: EcsScalingPolicyDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: cpuutilization
                                        type: EcsScalingPolicyDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: scalabletarget
                                        type: EcsScalableTargetDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                  artifacts:
                                    primary:
                                      primaryArtifactRef: artifact
                                      sources:
                                        - identifier: artifact
                                          type: Ecr
                                          spec:
                                            connectorRef: ${var.provider_connector_int}
                                            imagePath: <+pipeline.variables.ecr_repository>
                                            tag: <+pipeline.sequenceId>
                                            region: <+pipeline.variables.region>
                                  variables:
                                    - name: environment
                                      type: String
                                      description: environment name
                                      value: <+pipeline.variables.environment>
                                      required: true
                          execution:
                            steps:
                              - step:
                                  identifier: ecsRollingDeploy
                                  type: EcsRollingDeploy
                                  timeout: 10m
                              - step:
                                  identifier: Verify
                                  type: Verify
                                  spec:
                                    type: Auto
                                    spec:
                                      sensitivity: LOW
                                      duration: 10m
                                  timeout: 1h
                  variables:
                    - name: environment
                      type: String
                      value: ${app_value[0].environment}
                    - name: application
                      type: String
                      value: ${app_key}
                    - name: repository
                      type: String
                      value: ${repo}
                    - name: ecs_cluster
                      type: String
                      value: ${app_value[0].ecs_cluster}
                    - name: ecr_repository
                      type: String
                      value: ${app_value[0].ecr_repository}
                    - name: region
                      type: String
                      value: ${app_value[0].region}
                    - name: aws_account_id
                      type: String
                      value: "${app_value[0].aws_account_id}"
                    - name: branch
                      type: String
                      value: <+trigger.targetBranch>
        EOT
      }
    ]
  ])

  bat_inputsets = flatten([
    for repo, apps in local.yaml_config_bat : [
      for app_key, app_value in apps : {
        name        = "${repo}-${app_key}-is"
        identifier  = "${replace("${repo}-${app_key}-is", "-", "")}"
        org_id      = var.org_id
        project_id  = var.project_id
        pipeline_id = "${replace(var.bat_pipeline_name, "-", "")}"
        yaml        = <<-EOT
          inputSet:
            name: ${repo}-${app_key}-is
            identifier: ${replace("${repo}-${app_key}-is", "-", "")}
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
            pipeline:
              identifier: ${replace(var.bat_pipeline_name, "-", "")}
              template:
                templateInputs:
                  properties:
                    ci:
                      codebase:
                        connectorRef: ${var.repository_connector}
                        repoName: <+pipeline.variables.repository>
                        build:
                          type: branch
                          spec:
                            branch: <+pipeline.variables.branch>
                  stages:
                    - stage:
                        identifier: buildandpushtoecr
                        type: CI
                        spec:
                          infrastructure:
                            type: KubernetesDirect
                            spec:
                              connectorRef: org.${var.kubernetes_delegate_connector_nonprod}
                              namespace: ${var.kubernetes_delegate_connector_ns_nonprod}
                              serviceAccountName: ${var.kubernetes_delegate_connector_sa_nonprod}
                              os: Linux
                          execution:
                            steps:
                              - step:
                                  identifier: BuildAndPushECR
                                  type: BuildAndPushECR
                                  spec:
                                    connectorRef: ${var.provider_connector_bat}
                                    region: <+pipeline.variables.region>
                                    account: <+pipeline.variables.aws_account_id>
                                    imageName: <+pipeline.variables.ecr_repository>
                                    caching: true
                                    dockerfile: apps/${app_key}/Dockerfile
                                    resources:
                                      limits:
                                        memory: ${app_value[0].limit_memory}
                                        cpu: "${app_value[0].limit_cpu}"
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
                                      minimumCount: 1
                                      userGroups:
                                        - ${var.developers_user_group}
                                        - ${var.devops_user_group}
                    - stage:
                        identifier: deploytoecs
                        type: Deployment
                        spec:
                          environment:
                            environmentRef: ${app_value[0].environment}
                            infrastructureDefinitions:
                              - identifier: ${replace(local.env_account_map["bat"], "-", "")}ecs
                                inputs:
                                  identifier: ${replace(local.env_account_map["bat"], "-", "")}ecs
                                  type: ECS
                                  spec:
                                    connectorRef: ${var.provider_connector_bat}
                                    region: <+pipeline.variables.region>
                                    cluster: <+pipeline.variables.ecs_cluster>
                          service:
                            serviceRef: ${replace("${repo}-${app_key}-ecs-svc", "-", "")}
                            serviceInputs:
                              serviceDefinition:
                                type: ECS
                                spec:
                                  manifests:
                                    - manifest:
                                        identifier: taskdefinition
                                        type: EcsTaskDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: servicedefinition
                                        type: EcsServiceDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: memoryutilization
                                        type: EcsScalingPolicyDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: cpuutilization
                                        type: EcsScalingPolicyDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: scalabletarget
                                        type: EcsScalableTargetDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                  artifacts:
                                    primary:
                                      primaryArtifactRef: artifact
                                      sources:
                                        - identifier: artifact
                                          type: Ecr
                                          spec:
                                            connectorRef: ${var.provider_connector_bat}
                                            imagePath: <+pipeline.variables.ecr_repository>
                                            tag: <+pipeline.sequenceId>
                                            region: <+pipeline.variables.region>
                                  variables:
                                    - name: environment
                                      type: String
                                      description: environment name
                                      value: <+pipeline.variables.environment>
                                      required: true
                          execution:
                            steps:
                              - step:
                                  identifier: ecsRollingDeploy
                                  type: EcsRollingDeploy
                                  timeout: 10m
                              - step:
                                  identifier: Verify
                                  type: Verify
                                  spec:
                                    type: Auto
                                    spec:
                                      sensitivity: LOW
                                      duration: 10m
                                  timeout: 1h
                  variables:
                    - name: environment
                      type: String
                      value: ${app_value[0].environment}
                    - name: application
                      type: String
                      value: ${app_key}
                    - name: repository
                      type: String
                      value: ${repo}
                    - name: ecs_cluster
                      type: String
                      value: ${app_value[0].ecs_cluster}
                    - name: ecr_repository
                      type: String
                      value: ${app_value[0].ecr_repository}
                    - name: region
                      type: String
                      value: ${app_value[0].region}
                    - name: aws_account_id
                      type: String
                      value: "${app_value[0].aws_account_id}"
                    - name: branch
                      type: String
                      value: <+trigger.targetBranch>
        EOT
      }
    ]
  ])

  release_inputsets = flatten([
    for repo, apps in local.yaml_config_release : [
      for app_key, app_value in apps : {
        name        = "${repo}-${app_key}-is"
        identifier  = "${replace("${repo}-${app_key}-is", "-", "")}"
        org_id      = var.org_id
        project_id  = var.project_id
        pipeline_id = "${replace(var.release_pipeline_name, "-", "")}"
        yaml        = <<-EOT
          inputSet:
            name: ${repo}-${app_key}-is
            identifier: ${replace("${repo}-${app_key}-is", "-", "")}
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
            pipeline:
              identifier: ${replace(var.release_pipeline_name, "-", "")}
              template:
                templateInputs:
                  properties:
                    ci:
                      codebase:
                        connectorRef: ${var.repository_connector}
                        repoName: <+pipeline.variables.repository>
                        build:
                          type: branch
                          spec:
                            branch: <+pipeline.variables.branch>
                  stages:
                    - stage:
                        identifier: buildandpushtoecr
                        type: CI
                        spec:
                          infrastructure:
                            type: KubernetesDirect
                            spec:
                              connectorRef: org.${var.kubernetes_delegate_connector_nonprod}
                              namespace: ${var.kubernetes_delegate_connector_ns_nonprod}
                              serviceAccountName: ${var.kubernetes_delegate_connector_sa_nonprod}
                              os: Linux
                          execution:
                            steps:
                              - step:
                                  identifier: BuildAndPushECR
                                  type: BuildAndPushECR
                                  spec:
                                    connectorRef: ${var.provider_connector_preprod}
                                    region: <+pipeline.variables.region>
                                    account: <+pipeline.variables.aws_account_id>
                                    imageName: <+pipeline.variables.ecr_repository>
                                    caching: true
                                    dockerfile: apps/${app_key}/Dockerfile
                                    resources:
                                      limits:
                                        memory: ${app_value[0].limit_memory}
                                        cpu: "${app_value[0].limit_cpu}"
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
                                      minimumCount: 1
                                      userGroups:
                                        - ${var.developers_user_group}
                                        - ${var.devops_user_group}
                    - stage:
                        identifier: deploytoecs
                        type: Deployment
                        spec:
                          environment:
                            environmentRef: ${app_value[0].environment}
                            infrastructureDefinitions:
                              - identifier: ${replace(local.env_account_map["preprod"], "-", "")}ecs
                                inputs:
                                  identifier: ${replace(local.env_account_map["preprod"], "-", "")}ecs
                                  type: ECS
                                  spec:
                                    connectorRef: ${var.provider_connector_preprod}
                                    region: <+pipeline.variables.region>
                                    cluster: <+pipeline.variables.ecs_cluster>
                          service:
                            serviceRef: ${replace("${repo}-${app_key}-ecs-svc", "-", "")}
                            serviceInputs:
                              serviceDefinition:
                                type: ECS
                                spec:
                                  manifests:
                                    - manifest:
                                        identifier: taskdefinition
                                        type: EcsTaskDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: servicedefinition
                                        type: EcsServiceDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: memoryutilization
                                        type: EcsScalingPolicyDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: cpuutilization
                                        type: EcsScalingPolicyDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: scalabletarget
                                        type: EcsScalableTargetDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                  artifacts:
                                    primary:
                                      primaryArtifactRef: artifact
                                      sources:
                                        - identifier: artifact
                                          type: Ecr
                                          spec:
                                            connectorRef: ${var.provider_connector_preprod}
                                            imagePath: <+pipeline.variables.ecr_repository>
                                            tag: <+pipeline.sequenceId>
                                            region: <+pipeline.variables.region>
                                  variables:
                                    - name: environment
                                      type: String
                                      description: environment name
                                      value: <+pipeline.variables.environment>
                                      required: true
                          execution:
                            steps:
                              - step:
                                  identifier: ecsRollingDeploy
                                  type: EcsRollingDeploy
                                  timeout: 10m
                              - step:
                                  identifier: Verify
                                  type: Verify
                                  spec:
                                    type: Auto
                                    spec:
                                      sensitivity: LOW
                                      duration: 10m
                                  timeout: 1h
                  variables:
                    - name: environment
                      type: String
                      value: ${app_value[0].environment}
                    - name: application
                      type: String
                      value: ${app_key}
                    - name: repository
                      type: String
                      value: ${repo}
                    - name: ecs_cluster
                      type: String
                      value: ${app_value[0].ecs_cluster}
                    - name: ecr_repository
                      type: String
                      value: ${app_value[0].ecr_repository}
                    - name: region
                      type: String
                      value: ${app_value[0].region}
                    - name: aws_account_id
                      type: String
                      value: "${app_value[0].aws_account_id}"
                    - name: branch
                      type: String
                      value: <+trigger.targetBranch>
        EOT
      }
    ]
  ])

  main_inputsets = flatten([
    for repo, apps in local.yaml_config_main : [
      for app_key, app_value in apps : {
        name        = "${repo}-${app_key}-is"
        identifier  = "${replace("${repo}-${app_key}-is", "-", "")}"
        org_id      = var.org_id
        project_id  = var.project_id
        pipeline_id = "${replace(var.main_pipeline_name, "-", "")}"
        yaml        = <<-EOT
          inputSet:
            name: ${repo}-${app_key}-is
            identifier: ${replace("${repo}-${app_key}-is", "-", "")}
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
            pipeline:
              identifier: ${replace(var.main_pipeline_name, "-", "")}
              template:
                templateInputs:
                  properties:
                    ci:
                      codebase:
                        connectorRef: ${var.repository_connector}
                        repoName: <+pipeline.variables.repository>
                        build:
                          type: branch
                          spec:
                            branch: <+pipeline.variables.branch>
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
                                      minimumCount: 1
                                      userGroups:
                                        - ${var.devops_user_group}
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
                                    ticketNumber: ""
                    - stage:
                        identifier: buildandpushtoecr
                        type: CI
                        spec:
                          infrastructure:
                            type: KubernetesDirect
                            spec:
                              connectorRef: org.${var.kubernetes_delegate_connector_prod}
                              namespace: ${var.kubernetes_delegate_connector_ns_prod}
                              serviceAccountName: ${var.kubernetes_delegate_connector_sa_prod}
                              os: Linux
                          execution:
                            steps:
                              - step:
                                  identifier: BuildAndPushECR
                                  type: BuildAndPushECR
                                  spec:
                                    connectorRef: ${var.provider_connector_prod}
                                    region: <+pipeline.variables.region>
                                    account: <+pipeline.variables.aws_account_id>
                                    imageName: <+pipeline.variables.ecr_repository>
                                    caching: true
                                    dockerfile: apps/${app_key}/Dockerfile
                                    resources:
                                      limits:
                                        memory: ${app_value[0].limit_memory}
                                        cpu: "${app_value[0].limit_cpu}"
                    - stage:
                        identifier: deploytoecs
                        type: Deployment
                        spec:
                          environment:
                            environmentRef: ${app_value[0].environment}
                            infrastructureDefinitions:
                              - identifier: ${replace(local.env_account_map["prod"], "-", "")}ecs
                                inputs:
                                  identifier: ${replace(local.env_account_map["prod"], "-", "")}ecs
                                  type: ECS
                                  spec:
                                    connectorRef: ${var.provider_connector_prod}
                                    region: <+pipeline.variables.region>
                                    cluster: <+pipeline.variables.ecs_cluster>
                          service:
                            serviceRef: ${replace("${repo}-${app_key}-ecs-svc", "-", "")}
                            serviceInputs:
                              serviceDefinition:
                                type: ECS
                                spec:
                                  manifests:
                                    - manifest:
                                        identifier: taskdefinition
                                        type: EcsTaskDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: servicedefinition
                                        type: EcsServiceDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: memoryutilization
                                        type: EcsScalingPolicyDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: cpuutilization
                                        type: EcsScalingPolicyDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                    - manifest:
                                        identifier: scalabletarget
                                        type: EcsScalableTargetDefinition
                                        spec:
                                          store:
                                            type: Github
                                            spec:
                                              connectorRef: ${var.repository_connector}
                                              repoName: <+pipeline.variables.repository>
                                              branch: <+pipeline.variables.branch>
                                  artifacts:
                                    primary:
                                      primaryArtifactRef: artifact
                                      sources:
                                        - identifier: artifact
                                          type: Ecr
                                          spec:
                                            connectorRef: ${var.provider_connector_prod}
                                            imagePath: <+pipeline.variables.ecr_repository>
                                            tag: <+pipeline.sequenceId>
                                            region: <+pipeline.variables.region>
                                  variables:
                                    - name: environment
                                      type: String
                                      description: environment name
                                      value: <+pipeline.variables.environment>
                                      required: true
                          execution:
                            steps:
                              - step:
                                  identifier: ecsRollingDeploy
                                  type: EcsRollingDeploy
                                  timeout: 10m
                              - step:
                                  identifier: Verify
                                  type: Verify
                                  spec:
                                    type: Auto
                                    spec:
                                      sensitivity: LOW
                                      duration: 10m
                                  timeout: 1h
                  variables:
                    - name: environment
                      type: String
                      value: ${app_value[0].environment}
                    - name: application
                      type: String
                      value: ${app_key}
                    - name: repository
                      type: String
                      value: ${repo}
                    - name: ecs_cluster
                      type: String
                      value: ${app_value[0].ecs_cluster}
                    - name: ecr_repository
                      type: String
                      value: ${app_value[0].ecr_repository}
                    - name: region
                      type: String
                      value: ${app_value[0].region}
                    - name: aws_account_id
                      type: String
                      value: "${app_value[0].aws_account_id}"
                    - name: branch
                      type: String
                      value: main
        EOT
      }
    ]
  ])

}

module "feature_inputsets" {
  source     = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-ecs-inputsets?ref=develop"
  input_sets = local.feature_inputsets
  tags       = local.default_tags_list
}

module "dev_inputsets" {
  source     = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-ecs-inputsets?ref=develop"
  input_sets = local.dev_inputsets
  tags       = local.default_tags_list
}

module "bat_inputsets" {
  source     = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-ecs-inputsets?ref=develop"
  input_sets = local.bat_inputsets
  tags       = local.default_tags_list
}

module "release_inputsets" {
  source     = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-ecs-inputsets?ref=develop"
  input_sets = local.release_inputsets
  tags       = local.default_tags_list
}

module "main_inputsets" {
  source     = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-ecs-inputsets?ref=develop"
  input_sets = local.main_inputsets
  tags       = local.default_tags_list
}