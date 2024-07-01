terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.109.0"
       }
    }

}

# Configure the Microsoft Azure Provider
provider "azurerm" {

    subscription_id = var.subscription-id
    features {}
}

