#Setting up providers with credentials to Kubernetes
provider "kubernetes" {
  host = var.server_url
  config_path = "${path.root}/kube_config_cluster.yml"
}

provider "helm" {
  kubernetes {
    host = var.server_url
      config_path = "${path.root}/kube_config_cluster.yml"
  }
}

#Install Cert-manager with Helm (Pre-req. by Rancher)

resource "kubernetes_namespace" "cert-manager-ns" {
  metadata {
    name = "cert-manager"
  }
  
  #Making sure Ranchers changes to metadata doesnt trigger Terraform to react to changes
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels
    ]
  }
}


resource "helm_release" "cert-manager" {
  depends_on = [
    kubernetes_namespace.cert-manager-ns
  ]

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"

  # Never Install CRDs at the same time for Production. This is just for POC
  set {
    name  = "installCRDs"
    value = "true"
  }
}

#Install Rancher with Helm
resource "kubernetes_namespace" "cattle-system" {
  metadata {
    name = "cattle-system"
  }
  
  #Making sure Ranchers changes to metadata doesnt trigger Terraform to react to changes
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels
    ]
  }
}

resource "helm_release" "rancher-helm" {
  depends_on = [
    kubernetes_namespace.cattle-system,
    helm_release.cert-manager
  ]

  name       = "rancher"
  version    = "v2.4.5"
  repository = "https://releases.rancher.com/server-charts/latest"
  chart      = "rancher"
  namespace  = "cattle-system"

  set {
    name  = "hostname"
    value = "rancher-meetup.tworm.com"
  }
}


resource "null_resource" "wait_for_url" {
  depends_on = [
    helm_release.rancher-helm
  ]

  provisioner "local-exec" {
    command = <<EOT
      # Wait until server is alive
      echo "Waiting until rancher server is ready ..."
      until $(curl --output /dev/null -k --silent --head --fail https://rancher-meetup.tworm.com/ping); do
        printf '.'
        sleep 3
      done
   EOT
  }
}


#---------------------
# Bootstraping Rancher
#---------------------

# Rancher resources
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

# Initialize Rancher server
resource "rancher2_bootstrap" "admin" {
  depends_on = [
    helm_release.rancher-helm,
    null_resource.wait_for_url
  ]

  provider = rancher2.bootstrap

  password  = "Meetup2020!"
  telemetry = true
}
