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
  password_length   = 16
  ssh_key           = ""
}

output "password" {
  value       = module.proxmox_cloudinit.password
  description = "Generated password for the VM"
  sensitive   = true
}
