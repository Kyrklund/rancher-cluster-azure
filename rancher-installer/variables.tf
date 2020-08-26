variable "server_url" {
    description = "API URL"
}

variable "kubeconfig" {
    description = "kubeconfig"
}

locals {
  kube_host                   = yamldecode(var.kubeconfig).clusters[0].cluster.server
  kube_client_certificate     = base64decode(yamldecode(var.kubeconfig).users[0].user.client-certificate-data)
  kube_client_key             = base64decode(yamldecode(var.kubeconfig).users[0].user.client-key-data)
  kube_cluster_ca_certificate = base64decode(yamldecode(var.kubeconfig).clusters[0].cluster.certificate-authority-data)
}