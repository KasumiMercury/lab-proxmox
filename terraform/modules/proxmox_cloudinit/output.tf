output "password" {
  value = random_password.password.result
  description = "Generated password for the VM"
  sensitive = true
}

output "vm_ip" {
  value = var.ip_address
  description = "IP address of the VM"
}

output "vm_name" {
  value = var.vm_name
  description = "Name of the VM"
}

output "ssh_connection" {
  value = "ssh ${var.username}@${var.ip_address}"
  description = "SSH connection command for the VM"
}
