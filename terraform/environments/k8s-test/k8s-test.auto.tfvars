# Single-node Talos cluster for trying changes before the k8s environment (destroy it when done)
# Keep the versions and schematic in sync with task proxmox:talos-template and environments/k8s
talos_version      = "v1.14.2"
kubernetes_version = "1.37.1"
schematic_id       = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
template           = "talos-template"
cloudinit_storage  = "strix0"
gateway            = "192.168.110.1"
pod_subnet         = "10.1.0.0/16"
service_subnet     = "10.152.183.0/24"

nodes = {
  "yesod" = {
    role           = "controlplane"
    target_node    = "yesod"
    vmid           = 919
    vm_name        = "k8s-test-yesod"
    ip_address     = "192.168.110.199"
    memory         = 4096
    network_bridge = "vmbr0"
    network_tag    = 100
  }
}
