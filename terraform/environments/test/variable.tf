variable "template" {
  description = "Template to clone from"
  type        = string
}

variable "cloudinit_storage" {
  description = "Storage for cloud-init disk"
  type        = string
}

variable "virtual_machine" {
  description = "Configuration for the virtual machine"
  type = object({
    target_node    = string
    vmid           = number
    vm_name        = string
    cores          = optional(number, 2)
    memory         = optional(number, 4096)
    network_bridge = optional(string, "vmbr0")
    network_tag    = optional(number, 0)
    disk_size      = optional(number, 32)
  })
}

variable "credentials_vm" {
  description = "Credentials for the VM"
  type = object({
    ip_address     = string
    gateway        = string
    username       = string
    password_length = number
    ssh_key        = string
  })
}
