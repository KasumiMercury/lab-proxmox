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
      version = "3.0.1-rc8"
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

module "proxmox_cloudinit" {
  source = "../../modules/proxmox_cloudinit"

  vmid              = var.virtual_machine.vmid
  vm_name           = var.virtual_machine.vm_name
  template          = var.template
  target_node       = var.virtual_machine.target_node
  ip_address        = var.credentials_vm.ip_address
  gateway           = var.credentials_vm.gateway
  network_bridge    = var.virtual_machine.network_bridge
  network_tag       = var.virtual_machine.network_tag
  cloudinit_storage = var.cloudinit_storage
  username          = var.credentials_vm.username
  password_length   = var.credentials_vm.password_length
  ssh_key           = var.credentials_vm.ssh_key
}

output "password" {
  value       = module.proxmox_cloudinit.password
  description = "Generated password for the VM"
  sensitive   = true
}
