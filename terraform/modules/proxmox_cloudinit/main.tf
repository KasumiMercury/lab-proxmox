resource "proxmox_vm_qemu" "cloudinit" {
  os_type    = "cloud-init"

  vmid        = 100
  name        = var.vm_name
  target_node = var.target_node

  agent = 1

  cores  = var.cores
  memory = var.memory

  boot = "order=scsi0"

  ipconfig0 = "ip=${var.ip_address}/24,gw=${var.gateway},ip6=dhcp"

  ciuser     = var.username
  cipassword = var.password

  serial {
    id = 0
  }

  disks {
    ide {
      ide1 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size    = "${var.disk_size}G"
        }
      }
    }
  }

  network {
    id       = 0
    bridge   = "vmbr0"
    tag      = 0
    model    = "virtio"
    firewall = true
  }
}
