locals {
  vm_configurations = {
    for vm_key, vm_instance in var.virtual_machines :
    vm_key => merge(
      vm_instance,
      var.credentials_vm[vm_key],
      {
        cloudinit_storage = var.cloudinit_storage
        template          = var.template
      }
    )
  }
}

module "proxmox_cloudinit" {
  for_each = local.vm_configurations
  source   = "../../modules/proxmox_cloudinit"

  vmid              = each.value.vmid
  vm_name           = each.value.vm_name
  template          = each.value.template
  target_node       = each.value.target_node
  cores             = each.value.cores
  memory            = each.value.memory
  disk_size         = each.value.disk_size
  disk_storage      = each.value.disk_storage
  ip_address        = each.value.ip_address
  ip_prefix_length  = each.value.ip_prefix_length
  nameserver        = var.nameserver
  gateway           = each.value.gateway
  network_bridge    = each.value.network_bridge
  network_tag       = each.value.network_tag
  cloudinit_storage = each.value.cloudinit_storage
  username          = each.value.username
  password_length   = each.value.password_length
  ssh_key           = each.value.ssh_key

  # Optional: attach cloud-init snippet to configure sudo/SSH hardening
  cicustom = var.cicustom
}

output "vm_passwords" {
  description = "A map of VM names to their generated passwords."
  value = {
    for vm_key, vm_instance in module.proxmox_cloudinit :
    vm_key => vm_instance.password
  }
  sensitive = true
}

output "vm_connection_info" {
  description = "Connection information for each VM"
  value = {
    for vm_key, vm_instance in module.proxmox_cloudinit :
    vm_key => {
      name           = vm_instance.vm_name
      ip_address     = vm_instance.vm_ip
      ssh_connection = vm_instance.ssh_connection
    }
  }
  sensitive = true
}

output "vm_credentials" {
  description = "VM credentials for Ansible inventory generation"
  value = {
    for vm_key, credentials in var.credentials_vm :
    vm_key => {
      username   = credentials.username
      ip_address = credentials.ip_address
    }
  }
  sensitive = true
}
