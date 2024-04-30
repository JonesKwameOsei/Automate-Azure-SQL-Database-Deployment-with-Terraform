terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.101.0"
    }
  }
  backend "azurerm" {
    resource_group_name     = "terraform-mssql-rg"
    storage_account_name    = "tfstorage01jones"
    container_name          = "tfstate"
    key                     = "GitHub-Terraform-rg-connectivity-001-jones"
  }
}


provider "azurerm" {
  features {}
}