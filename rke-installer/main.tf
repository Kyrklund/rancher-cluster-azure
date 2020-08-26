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

  services {

    kube_api {
      #service_cluster_ip_range = var.service_cluster_ip_range
      #service_node_port_range  = var.service_node_port_range
      pod_security_policy      = var.pod_security_policy
      secrets_encryption_config {
        enabled = true
      }
      always_pull_images = var.always_pull_images
      audit_log {
        enabled = true
        configuration {
          max_age    = 7
          max_backup = 7
          max_size   = 128
          policy     = jsonencode({"apiVersion":"audit.k8s.io/v1","kind":"Policy","rules":[{"level":"Metadata"}]})
        }
      }    
    }

    kube_controller {
      cluster_cidr             = var.cluster_cidr
      service_cluster_ip_range = var.service_cluster_ip_range
    }

    kubelet {
      cluster_domain     = var.cluster_domain
      #cluster_dns_server = var.cluster_dns_server
      fail_swap_on       = false
    }
  }

  addon_job_timeout = 60

  network {
    plugin = "canal"
  }

  authentication {
    strategy = "x509"
  }
  authorization {
    mode = "rbac"
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