output "kubeconfig" {
  description = "Admin kubeconfig"
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "talosconfig" {
  description = "talosctl client config"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "nodes" {
  description = "Node name, role and address"
  value       = { for k, n in var.nodes : k => { name = n.vm_name, role = n.role, ip_address = n.ip_address } }
}
