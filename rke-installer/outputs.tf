output "server_url" {
    value = rke_cluster.cluster.api_server_url
}

output "kubeconfig" {
    value = rke_cluster.cluster.kube_config_yaml
}