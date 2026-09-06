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
    cpu_type       = optional(string, "x86-64-v2-AES")
    memory         = optional(number, 4096)
    network_bridge = optional(string, "vmbr0")
    network_tag    = optional(number, 0)
    disk_size      = optional(number, 32)
    disk_storage   = optional(string, "local-lvm")
    # Ansible role of the VM; non-empty values become inventory groups "<env>_<role>" (e.g. k8s_control_plane)
    role = optional(string, "")
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

# Optional: cloud-init vendor-data snippet attached to all VMs.
# Passed to Proxmox as cicustom "vendor=<value>", so the user-data that Proxmox
# generates from ciuser / cipassword / sshkeys stays intact. "user=" is not
# supported on purpose: it would replace that user-data and drop the
# Terraform-managed user, password and SSH key.
# Example value: "local:snippets/password-auth.yml"
variable "cloudinit_vendor_snippet" {
  description = "Proxmox snippet reference (<storage>:snippets/<file>) used as cloud-init vendor-data for all VMs (optional)"
  type        = string
  default     = null
  validation {
    condition     = var.cloudinit_vendor_snippet == null || can(regex("^[^:=,]+:snippets/.+$", var.cloudinit_vendor_snippet))
    error_message = "Must be a Proxmox snippet reference like \"local:snippets/password-auth.yml\" (no \"user=\"/\"vendor=\" prefix)."
  }
}
