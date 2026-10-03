nameserver = "192.168.0.1"

# Nextcloud migrated from the athanor VM (102, Docker Compose).
# Code, config and data live on the mp0 volume on monad (yesod's local 2TB HDD), so the container stays on yesod.
containers = {
  "athanor" = {
    target_node = "yesod"
    vmid        = 102
    hostname    = "athanor"
    ostemplate  = "strix0:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    cores       = 2
    memory      = 2048
    swap        = 512
    rootfs_size = 16
    mountpoints = [
      { storage = "monad", size = 500, mp = "/mnt/monad" },
    ]
    network_bridge = "vmbr0"
    network_tag    = 100
    role           = "nextcloud"
  }
}
