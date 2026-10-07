# Talos cluster: hod = control plane (also runs workloads), netzach / yesod = workers
# Keep the versions and schematic in sync with task proxmox:talos-template
talos_version      = "v1.14.2"
kubernetes_version = "1.37.1"
schematic_id       = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
template           = "talos-template"
cloudinit_storage  = "strix0"
gateway            = "192.168.110.1"
# Same as MicroK8s had; Talos' default Service CIDR (10.96.0.0/12) overlaps the Gateway LB pool 10.100.0.0/28
# (lab-argo platform/public-gateway). The pod subnet is repeated in lab-cilium values.yaml.
pod_subnet     = "10.1.0.0/16"
service_subnet = "10.152.183.0/24"

nodes = {
  "hod" = {
    role           = "controlplane"
    target_node    = "hod"
    vmid           = 810
    vm_name        = "k8s-hod"
    ip_address     = "192.168.110.181"
    memory         = 10240
    network_bridge = "vmbr100"
  }
  "netzach" = {
    role           = "worker"
    target_node    = "netzach"
    vmid           = 820
    vm_name        = "k8s-netzach"
    ip_address     = "192.168.110.182"
    memory         = 6144
    network_bridge = "vmbr0"
    network_tag    = 100
  }
  "yesod" = {
    role           = "worker"
    target_node    = "yesod"
    vmid           = 830
    vm_name        = "k8s-yesod"
    ip_address     = "192.168.110.183"
    memory         = 6144
    network_bridge = "vmbr0"
    network_tag    = 100
  }
}
