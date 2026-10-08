module "talos_cluster" {
  source = "../../modules/talos_cluster"

  cluster_name       = basename(abspath(path.root))
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  schematic_id       = var.schematic_id
  template           = var.template
  cloudinit_storage  = var.cloudinit_storage
  gateway            = var.gateway
  nameserver         = var.nameserver
  pod_subnet         = var.pod_subnet
  admin_cidrs        = var.admin_cidrs
  service_subnet     = var.service_subnet
  nodes              = var.nodes
  config_patches     = var.config_patches
}

output "kubeconfig" {
  value     = module.talos_cluster.kubeconfig
  sensitive = true
}

output "talosconfig" {
  value     = module.talos_cluster.talosconfig
  sensitive = true
}

output "nodes" {
  value = module.talos_cluster.nodes
}
