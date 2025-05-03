terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.1-rc8"
    }
  }
}

provider "proxmox" {
  pm_api_url      = ""
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "cloudinit" {
  vmid = 100
  name = var.vm_name
  cores = var.cores
  memory = var.memory
}