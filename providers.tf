terraform {
  required_version = ">= 0.13"
  required_providers {
    rke = {
      source = "rancher/rke"
    }
    rancher2 = {
      source = "rancher/rancher2"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "azurerm" {
    tenant_id  = "481cb5c3-c38b-45ce-976a-32cfaad9c160"
    subscription_id = "d5c795f5-43fc-4e6e-b8e9-658bbbd864da"
    features {}
}