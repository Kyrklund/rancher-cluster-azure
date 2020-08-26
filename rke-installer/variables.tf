variable "nodes" {
  type = list
}

variable "ssh_key" {
  description = "Private SSH key to access node"
}

variable "cluster_name" {
  type    = string
  default = "rancher_cluster"
}

variable "rke_config_path" {
  default = "./outputs/cluster.yml"
  type    = string
}

variable "service_cluster_ip_range" {
  default     = "172.17.0.0/16"
  type        = string
  description = "This is the virtual IP address that will be assigned to services created on Kubernetes. By default, the service cluster IP range is 172.16.0.0/16. If you change this value, then it must also be set with the same value on the Kubernetes Controller Manager (kube-controller)"
}

variable "cluster_cidr" {
  default     = "172.16.0.0/16"
  type        = string
  description = "CIDR pool used to assign IP addresses to pods in the cluster"
}

variable cluster_domain {
  type        = string
  default     = "cluster.local"
  description = "Base domain for the cluster"
}

variable cluster_dns_server {
  type        = string
  default     = "172.17.0.10"
  description = "IP address for the DNS service endpoint"
}

variable network_plugin {
  type        = string
  default     = "canal"
  description = "Network plugin to be used. Can be on of following Flannel, Calico, Canal and Weave. Canal is default"
}

variable "depend_on_tcs_id" {
  type    = string
  default = ""
}

variable service_node_port_range {
  type        = string
  default     = "30000-32767"
  description = "Expose a different port range for NodePort services"
}

variable pod_security_policy {
  type        = string
  default     = "false"
  description = "An option to enable the Kubernetes Pod Security Policy"
}

variable always_pull_images {
  type        = string
  default     = "false"
  description = "Enable AlwaysPullImages Admission controller plugin"
}

variable private_registry {
  type        = string
  default     = "diva.teliacompany.net:7813"
  description = "prefix for registry url"
}


variable private_registry_user {
  type        = string
  default     = null
  description = "user for privat registry"
}

variable private_registry_password {
  type        = string
  default     = null
  description = "base64 encoded password for private_registry_user"
}

variable rancher_k8s_version {
  type        = string
  default     = "v1.17.2-rancher1-2"
  description = "Rancher k8s version"
}

variable "default_pod_security_policy_template_id" {
  type = string
  default = "unrestricted"
  description = "templatev id for pod_security_policy"
}

variable "enable_network_policy" {
  type = string
  default = "true"
  description = "An option to allow to define specific networking rules"
}

variable "enable_cluster_monitoring" {
  type = string
  default = "true"
  description = "An option to enable or disable cluster_monitoring"
}