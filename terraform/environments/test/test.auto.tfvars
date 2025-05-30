template = "noble-template"
cloudinit_storage = "strix0"

virtual_machine = {
  target_node = "hod"
  vmid        = 810
  vm_name     = "test-vm"
  cores      = 2
  memory     = 4096
  network_bridge = "vmbr100"
  network_tag    = 0
  disk_size      = 32
}
