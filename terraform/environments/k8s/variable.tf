// ...existing code...
variable "template" {
  description = "Template to clone from"
  type        = string
}

variable "cloudinit_storage" {
  description = "Storage for cloud-init disk"
  type        = string
}

variable "virtual_machines" {
  description = "A map of virtual machines to create. Each key is a VM identifier, and the value is an object with VM specific configurations."
  type = map(object({
    target_node       = string
    vmid              = number
    vm_name           = string
    cores             = optional(number, 2)
    memory            = optional(number, 4096)
    ip_address        = string
    gateway           = string
    network_bridge    = optional(string, "vmbr0")
    network_tag       = optional(number, 0)
    disk_size         = optional(number, 32)
    username          = string
    password_length   = number
    ssh_key_path      = optional(string, "~/.ssh/id_ed25519.pub")
  }))
  default = {}
}