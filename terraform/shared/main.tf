locals {
  # Environment name = directory of the root module (terraform/environments/<env>)
  environment = basename(abspath(path.root))

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

  ct_configurations = {
    for ct_key, ct_instance in var.containers :
    ct_key => merge(ct_instance, var.credentials_ct[ct_key])
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
  cpu_type          = each.value.cpu_type
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
  tags              = compact([local.environment, each.value.role, "terraform"])

  # Optional vendor-data snippet (SSH policy etc.). User-data stays Proxmox-generated.
  cicustom = var.cloudinit_vendor_snippet == null ? null : "vendor=${var.cloudinit_vendor_snippet}"
}

module "proxmox_lxc" {
  for_each = local.ct_configurations
  source   = "../../modules/proxmox_lxc"

  vmid             = each.value.vmid
  hostname         = each.value.hostname
  target_node      = each.value.target_node
  ostemplate       = each.value.ostemplate
  cores            = each.value.cores
  memory           = each.value.memory
  swap             = each.value.swap
  onboot           = each.value.onboot
  protection       = each.value.protection
  rootfs_storage   = each.value.rootfs_storage
  rootfs_size      = each.value.rootfs_size
  mountpoints      = each.value.mountpoints
  ip_address       = each.value.ip_address
  ip_prefix_length = each.value.ip_prefix_length
  nameserver       = var.nameserver
  gateway          = each.value.gateway
  network_bridge   = each.value.network_bridge
  network_tag      = each.value.network_tag
  password_length  = each.value.password_length
  ssh_key          = each.value.ssh_key
}

# Outputs cover VMs and containers alike (containers log in as root)
output "vm_passwords" {
  description = "A map of VM and container names to their generated passwords."
  value = merge(
    { for vm_key, vm_instance in module.proxmox_cloudinit : vm_key => vm_instance.password },
    { for ct_key, ct_instance in module.proxmox_lxc : ct_key => ct_instance.password },
  )
  sensitive = true
}

output "vm_connection_info" {
  description = "Connection information for each VM and container"
  value = merge(
    {
      for vm_key, vm_instance in module.proxmox_cloudinit :
      vm_key => {
        name           = vm_instance.vm_name
        ip_address     = vm_instance.vm_ip
        ssh_connection = vm_instance.ssh_connection
        role           = var.virtual_machines[vm_key].role
      }
    },
    {
      for ct_key, ct_instance in module.proxmox_lxc :
      ct_key => {
        name           = ct_instance.hostname
        ip_address     = ct_instance.ct_ip
        ssh_connection = ct_instance.ssh_connection
        role           = var.containers[ct_key].role
      }
    },
  )
  sensitive = true
}

output "vm_credentials" {
  description = "VM and container credentials for Ansible inventory generation"
  value = merge(
    {
      for vm_key, credentials in var.credentials_vm :
      vm_key => {
        username   = credentials.username
        ip_address = credentials.ip_address
      }
    },
    {
      for ct_key, credentials in var.credentials_ct :
      ct_key => {
        username   = "root"
        ip_address = credentials.ip_address
      }
    },
  )
  sensitive = true
}
