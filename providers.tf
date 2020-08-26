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