terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.1-rc8"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

module "proxmox_cloudinit" {
  source = "../../modules/proxmox_cloudinit"

  vmid              = 300
  vm_name           = "test-vm"
  template          = "noble-template"
  target_node       = "hod"
  ip_address        = "192.168.110.111"
  gateway           = "192.168.110.1"
  network_bridge    = "vmbr100"
  network_tag       = 0
  cloudinit_storage = "strix0"
  username          = "test"
  password_length = 16
}

output "password" {
  value = module.proxmox_cloudinit.password
  description = "Generated password for the VM"
  sensitive   = true
}
