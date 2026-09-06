resource "random_password" "password" {
  length  = var.password_length
  special = true
}

resource "proxmox_vm_qemu" "basic_cloudinit" {
  os_type    = "cloud-init"
  clone      = var.template
  boot       = "order=scsi0"
  full_clone = false
  scsihw     = "virtio-scsi-single"

  vmid        = var.vmid
  name        = var.vm_name
  target_node = var.target_node

  agent = 0

  memory = var.memory

  ipconfig0 = "ip=${var.ip_address}/${var.ip_prefix_length},gw=${var.gateway},ip6=dhcp"

  nameserver = var.nameserver

  ciuser = var.username
  # cipassword = var.password
  cipassword = random_password.password.result
  sshkeys    = var.ssh_key

  cpu {
    cores = var.cores
  }

  serial {
    id   = 0
    type = "socket"
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
          storage = var.disk_storage
          size    = "${var.disk_size}G"
        }
      }
    }
  }

  network {
    id       = 0
    bridge   = var.network_bridge
    tag      = var.network_tag
    model    = "virtio"
    firewall = true
  }

  # Optional: attach cloud-init custom user-data snippet
  # e.g., var.cicustom = "user=local:snippets/ansible-user.yml"
  # This can configure NOPASSWD sudo and disable SSH password auth.
  cicustom = var.cicustom
}
