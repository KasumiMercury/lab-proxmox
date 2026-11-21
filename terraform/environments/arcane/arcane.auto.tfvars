nameserver = "192.168.0.1"

containers = {
  "kether" = {
    target_node    = "hod"
    vmid           = 106
    hostname       = "kether"
    ostemplate     = "strix0:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    cores          = 2
    memory         = 1024
    swap           = 512
    rootfs_size    = 16
    network_bridge = "vmbr100"
    role           = "manager"
  }
  "binah" = {
    target_node    = "yesod"
    vmid           = 107
    hostname       = "binah"
    ostemplate     = "strix0:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    cores          = 2
    memory         = 1024
    swap           = 512
    rootfs_size    = 16
    network_bridge = "vmbr0"
    network_tag    = 100
    role           = "agent"
  }
  "chesed" = {
    target_node    = "netzach"
    vmid           = 108
    hostname       = "chesed"
    ostemplate     = "strix0:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    cores          = 2
    memory         = 1024
    swap           = 512
    rootfs_size    = 16
    network_bridge = "vmbr0"
    network_tag    = 100
    role           = "agent"
  }
}
