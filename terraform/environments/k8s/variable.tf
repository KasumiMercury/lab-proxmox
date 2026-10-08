variable "talos_version" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "schematic_id" {
  type = string
}

variable "template" {
  type = string
}

variable "cloudinit_storage" {
  type = string
}

variable "gateway" {
  type = string
}

variable "nameserver" {
  type    = string
  default = "8.8.8.8"
}

variable "admin_cidrs" {
  description = "Networks allowed to reach the Talos API and the Kubernetes API (the admin LAN and the tailnet)"
  type        = list(string)
  default     = ["192.168.0.0/24", "100.64.0.0/10"]
}

variable "pod_subnet" {
  type = string
}

variable "service_subnet" {
  type = string
}

variable "nodes" {
  description = "See modules/talos_cluster"
  type        = any
}

variable "config_patches" {
  type    = list(string)
  default = []
}
