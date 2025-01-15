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
  description = "AWS Environments"
  type        = list(any)
}

variable "account_names" {
  description = "AWS account name"
  type        = list(any)
}

variable "cross_account_role_arns" {
  description = "Cross account role arns for IRSA"
  type        = list(any)
}

variable "kubernetes_delegate_nonprod" {
  description = "Kubernetes nonprod delegate"
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

variable "kubernetes_delegate_prod" {
  description = "Kubernetes prod delegate"
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

variable "region" {
  description = "AWS region"
  type        = string
}