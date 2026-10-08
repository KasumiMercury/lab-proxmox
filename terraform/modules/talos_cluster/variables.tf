variable "cluster_name" {
  description = "Talos / Kubernetes cluster name"
  type        = string
}

variable "talos_version" {
  description = "Talos version of the machine configs and the installer image (same as the template's image)"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version installed by Talos"
  type        = string
}

variable "schematic_id" {
  description = "Image Factory schematic of the template and the installer (system extensions)"
  type        = string
}

variable "template" {
  description = "Proxmox VM template to clone (task proxmox:talos-template)"
  type        = string
}

variable "cloudinit_storage" {
  description = "Storage of the cloud-init drive, which hands the static network config to Talos (nocloud)"
  type        = string
}

variable "gateway" {
  description = "Default gateway of the nodes"
  type        = string
}

variable "nameserver" {
  description = "DNS server of the nodes"
  type        = string
}

variable "ip_prefix_length" {
  description = "Prefix length of the node addresses"
  type        = number
  default     = 24
}

variable "pod_subnet" {
  description = "Pod CIDR (also Cilium's cluster-pool range in lab-cilium values.yaml)"
  type        = string
}

variable "admin_cidrs" {
  description = "Networks allowed to reach the Talos API (50000) and the Kubernetes API (6443) besides the cluster itself"
  type        = list(string)
}

variable "service_subnet" {
  description = "Service CIDR"
  type        = string
}

variable "nodes" {
  description = "Cluster nodes keyed by hostname-ish identifier; exactly one controlplane"
  type = map(object({
    role           = string
    target_node    = string
    vmid           = number
    vm_name        = string
    ip_address     = string
    cores          = optional(number, 2)
    cpu_type       = optional(string, "x86-64-v3")
    memory         = optional(number, 4096)
    disk_size      = optional(number, 32)
    disk_storage   = optional(string, "local-lvm")
    network_bridge = optional(string, "vmbr0")
    network_tag    = optional(number, 0)
  }))
  validation {
    condition     = alltrue([for n in values(var.nodes) : contains(["controlplane", "worker"], n.role)])
    error_message = "role must be controlplane or worker."
  }
  validation {
    condition     = length([for n in values(var.nodes) : n if n.role == "controlplane"]) == 1
    error_message = "Exactly one controlplane node is supported (the API endpoint is its address)."
  }
}

variable "config_patches" {
  description = "Extra machine config patches (YAML strings) applied to every node after the module's own"
  type        = list(string)
  default     = []
}
