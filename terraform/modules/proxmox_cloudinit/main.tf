resource "proxmox_vm_qemu" "cloudinit" {
  os_type    = "cloud-init"
  clone     = var.template

  vmid        = var.vmid
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
          storage = var.cloudinit_storage
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
    bridge   = "${var.network_bridge}"
    tag      = var.network_tag
    model    = "virtio"
    firewall = true
  }
}
