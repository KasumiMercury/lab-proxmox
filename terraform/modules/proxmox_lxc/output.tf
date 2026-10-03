output "password" {
  value       = random_password.password.result
  description = "Generated root password for the container"
  sensitive   = true
}

output "ct_ip" {
  value       = var.ip_address
  description = "IP address of the container"
}

output "hostname" {
  value       = var.hostname
  description = "Hostname of the container"
}

output "ssh_connection" {
  value       = "ssh root@${var.ip_address}"
  description = "SSH connection command for the container"
}
