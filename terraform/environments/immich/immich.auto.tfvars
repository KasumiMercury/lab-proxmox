nameserver = "192.168.0.1"

containers = {
  "chokmah" = {
    target_node = "yesod"
    vmid        = 105
    hostname    = "chokmah"
    ostemplate  = "strix0:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    cores       = 4
    memory      = 6144
    swap        = 2048
    rootfs_size = 32
    mountpoints = [
      { storage = "monad", size = 500, mp = "/mnt/monad" },
    ]
    network_bridge = "vmbr0"
    network_tag    = 100
    role           = "immich"
  }
}
