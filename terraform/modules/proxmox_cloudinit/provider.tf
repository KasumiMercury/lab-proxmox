terraform {
  required_version = ">= 1.11"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc10"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}
