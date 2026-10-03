resource "random_password" "password" {
  length  = var.password_length
  special = true
}

resource "proxmox_lxc" "container" {
  vmid         = var.vmid
  hostname     = var.hostname
  target_node  = var.target_node
  ostemplate   = var.ostemplate
  unprivileged = true

  # root password (console access); SSH uses the keys below
  password        = random_password.password.result
  ssh_public_keys = var.ssh_key

  cores  = var.cores
  memory = var.memory
  swap   = var.swap

  onboot     = var.onboot
  start      = true
  protection = var.protection

  nameserver = var.nameserver

  features {
    nesting = true
  }

  # The provider crashes without rootfs
  rootfs {
    storage = var.rootfs_storage
    size    = "${var.rootfs_size}G"
  }

  # Storage backed mount points (Proxmox creates the volume on the given storage)
  dynamic "mountpoint" {
    for_each = var.mountpoints
    content {
      key     = tostring(mountpoint.key)
      slot    = mountpoint.key
      storage = mountpoint.value.storage
      size    = "${mountpoint.value.size}G"
      mp      = mountpoint.value.mp
      backup  = mountpoint.value.backup
    }
  }

  network {
    name     = "eth0"
    bridge   = var.network_bridge
    tag      = var.network_tag == 0 ? null : var.network_tag
    ip       = "${var.ip_address}/${var.ip_prefix_length}"
    gw       = var.gateway
    firewall = true
  }

  lifecycle {
    # Destroying the container deletes every volume it owns, mount point data included.
    # Remove this guard (and set protection = false) on purpose before tearing a container down.
    prevent_destroy = true
    # Only applied at creation; a change would force a replacement
    ignore_changes = [ostemplate, password, ssh_public_keys]
  }
}
