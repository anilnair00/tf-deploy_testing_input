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
  
  dev_pipeline_template_yaml = <<-EOT
    template:
      name: ${var.dev_pipeline_template_name}
      identifier: ${replace(var.dev_pipeline_template_name, "-", "")}
      versionLabel: "1"
      type: Pipeline
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
      spec:
        stages:
          - stage:
              name: cdk-deploy-int
              identifier: cdkdeployint
              description: ""
              type: Custom
              spec:
                environment:
                  environmentRef: <+input>
                  deployToAll: false
                  environmentInputs: <+input>
                  infrastructureDefinitions: <+input>
                execution:
                  steps:
                    - stepGroup:
                        name: CDK Diff
                        identifier: CDK_Diff
                        steps:
                          - step:
                              type: GitClone
                              name: Git Clone
                              identifier: Git_Clone
                              spec:
                                connectorRef: <+input>
                                repoName: <+input>
                                cloneDirectory: /harness/
                                resources:
                                  limits:
                                    memory: <+input>
                                    cpu: <+input>
                                build:
                                  type: branch
                                  spec:
                                    branch: <+input>
                              when:
                                stageStatus: Success
                          - step:
                              type: Run
                              name: AWS CDK Diff
                              identifier: AWS_CDK_Diff
                              spec:
                                connectorRef: <+input>
                                image: <+input>
                                shell: Sh
                                command: |-
                                  apk update
                                  apk add py3-pip jq
                                  pip install awscli --break-system-packages
                                  assume_call=$(aws sts assume-role --role-arn $CDK_DEPLOYMENT_IAM_ROLE --role-session-name AWSCLI-session ) && assumed_aws_access_key=$(echo $assume_call | jq -r .Credentials.AccessKeyId ) && assumed_aws_access_secret_key=$(echo $assume_call | jq -r .Credentials.SecretAccessKey) && assumed_aws_session_token=$(echo $assume_call | jq -r .Credentials.SessionToken) && export AWS_ACCESS_KEY_ID=$assumed_aws_access_key && export AWS_SECRET_ACCESS_KEY=$assumed_aws_access_secret_key && export AWS_SESSION_TOKEN=$assumed_aws_session_token
                                  export NODE_OPTIONS="--max-old-space-size=4096"
                                  echo "Installing Dependencies ____________________"
                                  npm install
                                  npx cdk diff
                                envVariables:
                                  CDK_DEPLOYMENT_IAM_ROLE: <+input>
                                resources:
                                  limits:
                                    memory: <+input>
                                    cpu: <+input>
                              when:
                                stageStatus: Success
                                condition: "true"
                        stepGroupInfra:
                          type: KubernetesDirect
                          spec:
                            connectorRef: <+input>
                            namespace: <+input>
                            serviceAccountName: <+input>
                        when:
                          stageStatus: Success
                          condition: "true"
                    - step:
                        type: HarnessApproval
                        name: CDK Approval
                        identifier: CDK_Approval
                        spec:
                          approvalMessage: Please review the following information and approve the pipeline progression
                          includePipelineExecutionHistory: true
                          isAutoRejectEnabled: false
                          approvers:
                            userGroups: <+input>
                            minimumCount: <+input>
                            disallowPipelineExecutor: false
                          approverInputs: []
                        timeout: 8h
                    - stepGroup:
                        name: CDK Deploy
                        identifier: CDK_Deploy
                        steps:
                          - step:
                              type: GitClone
                              name: Git Clone
                              identifier: Git_Clone
                              spec:
                                connectorRef: <+input>
                                repoName: <+input>
                                cloneDirectory: /harness/
                                resources:
                                  limits:
                                    memory: <+input>
                                    cpu: <+input>
                                build:
                                  type: branch
                                  spec:
                                    branch: <+input>
                              when:
                                stageStatus: Success
                          - step:
                              type: Run
                              name: AWS CDK Deploy
                              identifier: AWS_CDK_Application_Deploy
                              spec:
                                connectorRef: <+input>
                                image: <+input>
                                shell: Sh
                                command: |-
                                  apk update
                                  apk add py3-pip jq
                                  pip install awscli --break-system-packages
                                  assume_call=$(aws sts assume-role --role-arn $CDK_DEPLOYMENT_IAM_ROLE --role-session-name AWSCLI-session ) && assumed_aws_access_key=$(echo $assume_call | jq -r .Credentials.AccessKeyId ) && assumed_aws_access_secret_key=$(echo $assume_call | jq -r .Credentials.SecretAccessKey) && assumed_aws_session_token=$(echo $assume_call | jq -r .Credentials.SessionToken) && export AWS_ACCESS_KEY_ID=$assumed_aws_access_key && export AWS_SECRET_ACCESS_KEY=$assumed_aws_access_secret_key && export AWS_SESSION_TOKEN=$assumed_aws_session_token
                                  export NODE_OPTIONS="--max-old-space-size=4096"
                                  echo "Installing Dependencies ____________________"
                                  npm install
                                  echo "CDK Synth -------------------------"
                                  npx cdk synth
                                  echo "CDK Deploy -------------------------"
                                  npx cdk deploy --require-approval never
                                envVariables:
                                  CDK_DEPLOYMENT_IAM_ROLE: <+input>
                                resources:
                                  limits:
                                    memory: <+input>
                                    cpu: <+input>
                              when:
                                stageStatus: Success
                                condition: "true"
                        stepGroupInfra:
                          type: KubernetesDirect
                          spec:
                            connectorRef: <+input>
                            namespace: <+input>
                            serviceAccountName: <+input>
                  rollbackSteps: []
                serviceDependencies: []
              tags: {}
  EOT

}

module "dev_pipeline_template" {
  source     = "git@github.com:AC-DevOpsTools-Management/ac-harness-tf-modules.git//modules/harness-pipeline-template?ref=develop"
  
  name       = var.dev_pipeline_template_name
  identifier = replace(var.dev_pipeline_template_name, "-", "")
  org_id     = var.org_id
  project_id = var.project_id
  template_version    = 1
  branch_name = var.harness_templates_branch_name
  file_path = "${replace("templates/cdk/${var.dev_pipeline_template_name}.yaml", "-", "")}"
  repository_connector = var.devops_repository_connector
  store_type           = "REMOTE"
  repository_name = var.harness_templates_repo_name
  yaml       = local.dev_pipeline_template_yaml
  tags       = local.default_tags_list
}