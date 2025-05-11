terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

module "proxmox_cloudinit" {
  source = "../../modules/proxmox_cloudinit"
  # TODO: set variables
}

output "password" {
  value = module.proxmox_cloudinit.password
  description = "Generated password for the VM"
  sensitive   = true
}
