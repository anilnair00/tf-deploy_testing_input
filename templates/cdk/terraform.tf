terraform {
  required_version = ">= 1.9"
  backend "s3" {
    bucket         = "ac-harness-resources-terraform-state"
    encrypt        = true
    key            = "harness/templates/cdk/ac-it-notifications-harness-resources-tf/ac-it-notifications-harness-resources-tf.tfstate"
    dynamodb_table = "ac-tools-tf-prod-cac1-state-lock"
    region         = "ca-central-1"
    role_arn       = var.S3_BACKEND_ROLE_ARN
  }
  required_providers {
    harness = {
      source = "harness/harness"
    }
  }
}