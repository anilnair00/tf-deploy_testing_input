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

variable "dev_pipeline_name" {
  description = "Harness pipeline name"
  type        = string
}

variable "bat_pipeline_name" {
  description = "Harness pipeline name"
  type        = string
}

variable "release_pipeline_name" {
  description = "Harness pipeline name"
  type        = string
}

variable "main_pipeline_name" {
  description = "Harness pipeline name"
  type        = string
}