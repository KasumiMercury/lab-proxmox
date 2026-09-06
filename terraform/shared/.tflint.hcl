# shared/ is not a Terraform root on its own; the files are symlinked into
# environments/<env>/, where the module path resolves. Skip module inspection here.
config {
  format           = "json"
  call_module_type = "none"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
