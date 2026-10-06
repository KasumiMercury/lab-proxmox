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
