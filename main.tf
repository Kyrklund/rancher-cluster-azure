provider "azurerm" {
    tenant_id  = "481cb5c3-c38b-45ce-976a-32cfaad9c160"
    subscription_id = "d5c795f5-43fc-4e6e-b8e9-658bbbd864da"
    features {}
}

#Create VMs
module "ranchervms" {
    source       = "./azure-vms"
    rg_name      = "rancher-demo"
    number_vms   = 3
}

#Set up Kubernets on VMs using RKE
module "rke-install" {
    source  = "./rke-installer"
    nodes   = module.ranchervms.nodes
    ssh_key = module.ranchervms.ssh_key
}

#Install Rancher on Kubernetes
module "rancher-install" {
    kubeconfig = module.rke-install.kubeconfig
    source     = "./rancher-installer"
    server_url = module.rke-install.server_url
}