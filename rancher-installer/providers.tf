terraform {
  required_version = ">= 0.13"
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
    }
  }
}

# Rancher2 bootstrapping provider
provider "rancher2" {
  alias = "bootstrap"

  api_url  = "https://rancher-meetup.tworm.com"
  insecure = true
  bootstrap = true
}

# Rancher2 administration provider
provider "rancher2" {
  alias = "admin"

  api_url  = "https://rancher-meetup.tworm.com"
  insecure = true
  token_key = rancher2_bootstrap.admin.token
}

#Setting up providers with credentials to Kubernetes
provider "kubernetes" {
  host        = var.server_url
  config_path = "kube_config_cluster.yml"
}

provider "helm" {
  kubernetes {
    host        = var.server_url
    config_path = "kube_config_cluster.yml"
  }
}