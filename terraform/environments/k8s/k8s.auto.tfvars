template          = "noble-template"
cloudinit_storage = "strix0"
# Enable SSH password auth via vendor-data (upload first: task pve:snippet HOST=user@hod)
# cloudinit_vendor_snippet = "strix0:snippets/password-auth.yml"

virtual_machines = {
  "hod" = {
    target_node    = "hod"
    vmid           = 810
    vm_name        = "k8s-hod"
    role           = "control-plane"
    cores          = 2
    memory         = 8192
    network_bridge = "vmbr100"
    network_tag    = 0
    disk_size      = 32
  }
  "netzach" = {
    target_node    = "netzach"
    vmid           = 829
    vm_name        = "k8s-netzach"
    role           = "worker"
    cores          = 2
    memory         = 4096
    network_bridge = "vmbr0"
    network_tag    = 100
    disk_size      = 32
  }
  "yesod" = {
    target_node    = "yesod"
    vmid           = 839
    vm_name        = "k8s-yesod"
    role           = "worker"
    cores          = 2
    memory         = 4096
    network_bridge = "vmbr0"
    network_tag    = 100
    disk_size      = 32
  }
}
