terraform {
  required_version = ">= 0.13"
  required_providers {
    rke = {
      source = "rancher/rke"
    }
  }
}

###################################
# The ssh socket is not ready when RKE tries to connect.
# RKE only does one try before failing...
# This test will loop untill SSH is ready before continuing with RKE
###################################
resource "null_resource" "ssh_test" {
  count = length(var.nodes)
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "rancher"
      host        = var.nodes[count.index].public_ip_address
      private_key = var.ssh_key

      # Permission denied without as command is run from /tmp
      # Script_path is just used to define where to run command (Not an actual file at location).
      script_path = "/home/rancher/ssh_test.sh"
    }
    inline = ["echo SSH socket ready!"]
  }
}

###################################
# Installing K8s with RKE
###################################
resource "rke_cluster" "cluster" {
  depends_on = [
    null_resource.ssh_test
  ]
  #Not pretty, but stops "Failed to set up SSH tunneling for host" errors
  delay_on_creation  = 60

  cluster_name       = var.cluster_name
  kubernetes_version = var.rancher_k8s_version

  dynamic "nodes" {
    for_each = var.nodes
    content {
      address           = nodes.value.public_ip_address
      internal_address  = nodes.value.private_ip_address
      hostname_override = nodes.value.computer_name
      role              = ["controlplane", "etcd", "worker"]
      port              = 22
      user              = "rancher"
      ssh_key           = var.ssh_key
    }
  }

  lifecycle {
    ignore_changes = [
      cluster_cidr,
      cluster_dns_server,
      cluster_domain,
      kube_config_yaml,
      rke_cluster_yaml,
      rke_state
    ]
  }
}

resource "local_file" "kube_cluster_yaml" {
  filename = "${path.root}/kube_config_cluster.yml"
  content  = rke_cluster.cluster.kube_config_yaml
 }