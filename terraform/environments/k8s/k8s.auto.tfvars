template          = "noble-template"
cloudinit_storage = "strix0"

virtual_machines = {
  "hod" = {
    target_node    = "hod"
    vmid           = 810
    vm_name        = "k8s"
    cores          = 2
    memory         = 4096
    network_bridge = "vmbr100"
    network_tag    = 0
    disk_size      = 32
  }
  # "netzach" = {
  #   target_node    = "netzach"
  #   vmid           = 820
  #   vm_name        = "k8s"
  #   cores          = 2
  #   memory         = 4096
  #   network_bridge = "vmbr0"
  #   network_tag    = 100
  #   disk_size      = 32
  # }
  # "yesod" = {
  #   target_node    = "yesod"
  #   vmid           = 830
  #   vm_name        = "k8s"
  #   cores          = 2
  #   memory         = 4096
  #   network_bridge = "vmbr0"
  #   network_tag    = 100
  #   disk_size      = 32
  # }
}
