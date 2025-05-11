output "password" {
  value = random_password.password.result
  description = "Generated password for the VM"
  sensitive = true
  depends_on = [ random_password.password ]
}
