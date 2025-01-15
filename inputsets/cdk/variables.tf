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

variable "feature_pipeline_name" {
  description = "Harness pipeline name"
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

variable "dev_pipeline_name" {
  description = "Harness pipeline name"
  type        = string
}

variable "repository_connector" {
  description = "Harness GitHub repository connector"
  type        = string
}

variable "kubernetes_delegate_connector_nonprod" {
  description = "Kubernetes nonprod delegate connector"
  type        = string
}

variable "kubernetes_delegate_connector_ns_nonprod" {
  description = "Kubernetes nonprod delegate connector namespace"
  type        = string
}

variable "kubernetes_delegate_connector_sa_nonprod" {
  description = "Kubernetes nonprod delegate connector service account"
  type        = string
}

variable "kubernetes_delegate_connector_prod" {
  description = "Kubernetes prod delegate connector"
  type        = string
}

variable "kubernetes_delegate_connector_ns_prod" {
  description = "Kubernetes prod delegate connector namespace"
  type        = string
}

variable "kubernetes_delegate_connector_sa_prod" {
  description = "Kubernetes prod delegate connector service account"
  type        = string
}

variable "provider_connector_int" {
  description = "Harness AWS Provider INT Connector"
  type        = string
}

variable "provider_connector_bat" {
  description = "Harness AWS Provider BAT Connector"
  type        = string
}

variable "provider_connector_preprod" {
  description = "Harness AWS Provider PREPROD Connector"
  type        = string
}

variable "provider_connector_prod" {
  description = "Harness AWS Provider PROD Connector"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "developers_user_group" {
  description = "Developers user group"
  type        = string
}

variable "devops_user_group" {
  description = "DevOps user group"
  type        = string
}

variable "dev_pipeline_id" {
  description = "The Harness dev Pipeline ID"
  type        = string
}