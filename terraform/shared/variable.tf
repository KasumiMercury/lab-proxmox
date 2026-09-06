variable "template" {
  description = "Proxmox VM template name to clone from (must exist on all target nodes)"
  type        = string
  validation {
    condition     = length(var.template) > 0
    error_message = "Template name cannot be empty."
  }
}

variable "cloudinit_storage" {
  description = "Storage pool name for cloud-init disk (must be available on all target nodes)"
  type        = string
  validation {
    condition     = length(var.cloudinit_storage) > 0
    error_message = "Cloud-init storage name cannot be empty."
  }
}

variable "virtual_machines" {
  description = "A map of virtual machines to create. Each key is a VM identifier, and the value is an object with VM specific configurations."
  type = map(object({
    target_node    = string
    vmid           = number
    vm_name        = string
    cores          = optional(number, 2)
    memory         = optional(number, 4096)
    network_bridge = optional(string, "vmbr0")
    network_tag    = optional(number, 0)
    disk_size      = optional(number, 32)
    disk_storage   = optional(string, "local-lvm")
  }))
}

variable "credentials_vm" {
  description = "Credentials for each VM, keyed by the same identifiers as virtual_machines"
  type = map(object({
    ip_address       = string
    gateway          = string
    username         = string
    password_length  = number
    ssh_key          = string
    ip_prefix_length = optional(number, 24)
  }))
}

variable "nameserver" {
  description = "DNS server configured on all VMs"
  type        = string
  default     = "8.8.8.8"
}

# Optional: attach a common cloud-init snippet to all VMs
# Example value: "user=local:snippets/ansible-user.yml"
variable "cicustom" {
  description = "Cloud-init custom snippet reference for all VMs (optional)"
  type        = string
  default     = null
}
