terraform {
  required_version = ">= 1.11"
  backend "s3" {
    bucket                      = "terraform"
    key                         = "proxmox/k8s/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    use_lockfile                = true
  }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc04"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

provider "cloudflare" {
  # token pulled from $CLOUDFLARE_API_TOKEN
}

provider "proxmox" {
  pm_tls_insecure = true
  # Proxmox API credentials expected via environment variables:
  # PM_API_URL, PM_USER, PM_PASS (or PM_API_TOKEN_ID and PM_API_TOKEN_SECRET)
}

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
  # for_each = var.virtual_machines
  for_each = local.vm_configurations
  source   = "../../modules/proxmox_cloudinit"

  vmid              = each.value.vmid
  vm_name           = each.value.vm_name
  template          = each.value.template
  target_node       = each.value.target_node
  ip_address        = each.value.ip_address
  gateway           = each.value.gateway
  network_bridge    = each.value.network_bridge
  network_tag       = each.value.network_tag
  cloudinit_storage = each.value.cloudinit_storage
  username          = each.value.username
  password_length   = each.value.password_length
  ssh_key           = each.value.ssh_key
}

output "vm_passwords" {
  description = "A map of VM names to their generated passwords."
  value = {
    for vm_key, vm_instance in module.proxmox_cloudinit :
    vm_key => vm_instance.password
  }
  sensitive = true
}
