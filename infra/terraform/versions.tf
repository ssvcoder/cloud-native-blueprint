terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  # ---------------------------------------------------------------------------
  # Remote state backend (placeholder).
  #
  # State is kept locally by default so this repo works out of the box.
  # For real use, uncomment the block below and create the storage account +
  # container first (never commit the access key — pass it via
  # -backend-config="access_key=$ARM_ACCESS_KEY" or an environment variable).
  #
  #   backend "azurerm" {
  #     resource_group_name  = "rg-terraform-state"
  #     storage_account_name = "sttfstate<unique>"
  #     container_name       = "tfstate"
  #     key                  = "blueprint/dev.terraform.tfstate"
  #   }
  # ---------------------------------------------------------------------------
}

provider "azurerm" {
  features {}
}
