terraform {
  required_version = ">= 1.9"
  backend "azurerm" {
    resource_group_name  = "Testvm_group"
    storage_account_name = "testvmgroupb7e2"
    container_name       = "tfstate"
    key                  = "dev.tfstate"
  }
  required_providers {
    harness = {
      source = "harness/harness"
    }
  }
}
