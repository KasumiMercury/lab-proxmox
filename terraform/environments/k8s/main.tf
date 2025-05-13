terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

module "proxmox_cloudinit" {
  for_each = var.virtual_machines
  source   = "../../modules/proxmox_cloudinit"

  vmid              = each.value.vmid
  vm_name           = each.value.vm_name
  template          = var.template
  target_node       = each.value.target_node
  ip_address        = each.value.ip_address
  gateway           = each.value.gateway
  network_bridge    = each.value.network_bridge
  network_tag       = each.value.network_tag
  cloudinit_storage = var.cloudinit_storage
  username          = each.value.username
  password_length   = each.value.password_length
  ssh_key_path      = each.value.ssh_key_path
}

output "vm_passwords" {
  description = "A map of VM names to their generated passwords."
  value = {
    for vm_key, vm_instance in module.proxmox_cloudinit :
    vm_key => vm_instance.password
  }
  sensitive   = true 
}