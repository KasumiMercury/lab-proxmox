nameserver = "192.168.0.1"

# Samba file server migrated from the former gnosis VM (also VMID 101, now deleted).
# The share lives on the mp0 volume on monad (yesod's local HDD), so the container stays on yesod.
containers = {
  "gnosis" = {
    target_node = "yesod"
    vmid        = 101
    hostname    = "gnosis"
    ostemplate  = "strix0:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    cores       = 2
    memory      = 1024
    swap        = 512
    mountpoints = [
      { storage = "monad", size = 800, mp = "/mnt/monad" },
    ]
    network_bridge = "vmbr0"
    network_tag    = 100
    role           = "samba"
  }
}
