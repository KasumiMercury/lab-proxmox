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
  # Keep the balloon device (minimum = memory, so it never shrinks the guest): Proxmox reads the guest's
  # own memory usage through it and free page reporting hands freed pages back to the host.
  # Without it (balloon = 0) Proxmox shows the QEMU RSS, which stays at the full allocation.
  balloon = var.memory

  # Without tags the provider writes " ", which never matches the config and shows up in every plan
  tags = length(var.tags) > 0 ? join(";", sort(distinct(var.tags))) : null

  ipconfig0 = "ip=${var.ip_address}/${var.ip_prefix_length},gw=${var.gateway},ip6=dhcp"

  nameserver = var.nameserver

  ciuser = var.username
  # cipassword = var.password
  cipassword = random_password.password.result
  sshkeys    = var.ssh_key

  cpu {
    cores = var.cores
    type  = var.cpu_type
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

  # Explicit, so the provider moves the state from the deprecated vm_state (kept on refresh while
  # power_state is unset) to power_state; running is what an unset value meant anyway
  power_state = "running"

  # The provider (since 3.0.2-rc07) reads an unset startup/shutdown config back as this block of -1s
  # ("any"/"default"), so leaving it out shows a removal on every plan
  # (https://github.com/Telmate/terraform-provider-proxmox/issues/1495)
  startup_shutdown {
    order            = -1
    shutdown_timeout = -1
    startup_delay    = -1
  }

  # Optional: attach cloud-init custom user-data snippet
  # e.g., var.cicustom = "user=local:snippets/ansible-user.yml"
  # This can configure NOPASSWD sudo and disable SSH password auth.
  cicustom = var.cicustom
}
