# Ansible Ops

## Inventory
- Generate: `task ansible:generate-inventory TF_ENV=<env>`
- File: `ansible/inventory/<env>.ini` with group `[<env>]`

## Inventory groups
- `scripts/generate_inventory.sh` writes `[<env>]` with every VM. VMs with a non-empty Terraform `role` are also listed in `[<env>_<role>]` (hyphens become underscores), e.g. `test_<role>`

## Playbooks
- `playbooks/setup.yml`: waits for SSH, then applies role `baseline` (Japanese locale, timezone, keyboard, bashtop)
- `task ansible:run TF_ENV=<env>` uses `playbooks/setup-<env>.yml` when it exists, otherwise `playbooks/setup.yml`
- Roles live in `roles/` (`roles_path` in `ansible.cfg`). The k8s environment (Talos) is not managed by Ansible; see "Kubernetes" in the top-level README

- `playbooks/setup-monitoring.yml` (`task monitoring:setup`): uses the static `inventory/hosts.yml` (groups `pve` and `nas`, hosts not created by Terraform) instead of a generated one. Roles `monitoring_server` (strix) and `pve_monitoring` (Proxmox nodes); see "Monitoring" in the top-level README
- `playbooks/setup-pve.yml` (`task pve:setup`): Proxmox node tuning on the static `inventory/hosts.yml`. Role `pve_nvme_power` limits NVMe APST on hod (kernel command line for the next boot, sysfs for the running system)
- `playbooks/setup-zabbix.yml` (`task zabbix:setup`): role `zabbix_server` on strix and `zabbix_agent` on the Proxmox nodes (static `inventory/hosts.yml`); see "Zabbix" in the top-level README

## SSH Auth
- `ANSIBLE_USE_PASSWORDS`: `true` or `false` (default: `false`) to include/exclude passwords in inventory

## Vault
- Create `.vault_pass.txt`: `task ansible:vault-passfile`
- Generate per-host vault vars: `task ansible:vault-hostvars-generate TF_ENV=<env>` → `inventory/host_vars/<vm>/vault.yml` (loaded automatically next to the inventory)
- `.vault_pass.txt` is passed via `--vault-password-file` by the Task targets (not configured in `ansible.cfg`)
- Inventory without passwords: `ANSIBLE_USE_PASSWORDS=false task ansible:generate-inventory TF_ENV=<env>`

## Other
- `ANSIBLE_REMOTE_USER` overrides the remote user
- `ANSIBLE_PRIVATE_KEY_FILE=~/.ssh/id_ed25519 task ansible:test-connection TF_ENV=test` to verify the key path

