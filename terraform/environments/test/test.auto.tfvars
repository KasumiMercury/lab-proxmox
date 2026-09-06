template          = "noble-template"
cloudinit_storage = "strix0"
# Enable SSH password auth via vendor-data (upload first: task proxmox:upload-snippet HOST=user@pve)
# cloudinit_vendor_snippet = "local:snippets/password-auth.yml"

virtual_machines = {
  "test" = {
    target_node    = "hod"
    vmid           = 810
    vm_name        = "test-vm"
    cores          = 2
    memory         = 4096
    network_bridge = "vmbr100"
    network_tag    = 0
    disk_size      = 32
  }
}
