variable "TF_VAR_HARNESS_ENDPOINT" {
  description = "Harness API endpoint"
  type        = string
}

variable "TF_VAR_HARNESS_ACCOUNT_ID" {
  description = "Harness account ID"
  type        = string
}

variable "TF_VAR_HARNESS_PLATFORM_API_KEY" {
  description = "Harness platform API key"
  type        = string
}
variable "org_id" {
  description = "Harness Organization ID"
  type        = string
}

variable "project_id" {
  description = "Harness Project ID"
  type        = string
}

variable "envs" {
  description = "AWS environments"
  type        = list(any)
}

variable "account_names" {
  description = "AWS account name"
  type        = list(any)
}

variable "deployment_type" {
  description = "Harness deployment type"
  type        = string
}

# variable "devops_repository_connector" {
#   description = "Identifier of the Harness Connector used for importing entity from Git"
#   type        = string
# }

# variable "harness_templates_repo_name" {
#   description = "Name of the repository"
#   type        = string
#   default     = null
# }

# variable "harness_templates_branch_name" {
#   description = "Name of the branch"
#   type        = string
#   default     = null
# }