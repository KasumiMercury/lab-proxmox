template          = "noble-template"
cloudinit_storage = "strix0"
# Enable SSH password auth via vendor-data (upload first: task proxmox:upload-snippet HOST=user@pve)
# cloudinit_vendor_snippet = "local:snippets/password-auth.yml"

virtual_machines = {
  "hod" = {
    target_node    = "hod"
    vmid           = 810
    vm_name        = "k8s-hod"
    cores          = 2
    memory         = 4096
    network_bridge = "vmbr100"
    network_tag    = 0
    disk_size      = 32
  }
  "netzach" = {
    target_node    = "netzach"
    vmid           = 820
    vm_name        = "k8s-netzach"
    cores          = 2
    memory         = 4096
    network_bridge = "vmbr0"
    network_tag    = 100
    disk_size      = 32
  }
  "yesod" = {
    target_node    = "yesod"
    vmid           = 830
    vm_name        = "k8s-yesod"
    cores          = 2
    memory         = 4096
    network_bridge = "vmbr0"
    network_tag    = 100
    disk_size      = 32
  }
}
