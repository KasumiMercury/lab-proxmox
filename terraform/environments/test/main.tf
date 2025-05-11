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

  vmid              = 300
  vm_name           = "test-vm"
  template          = "ubuntu-server-2404-template"
  target_node       = "hod"
  ip_address        = "192.168.110.111"
  gateway           = "192.168.110.1"
  network_bridge    = "vmbr0"
  network_tag       = 0
  cloudinit_storage = "strix0"
  username          = "test-user"
  password_length = 16
}

output "password" {
  value = module.proxmox_cloudinit.password
  description = "Generated password for the VM"
  sensitive   = true
}
