resource "proxmox_vm_qemu" "cloudinit" {
  vmid = 100
  name = var.vm_name
  cores = var.cores
  memory = var.memory
}
