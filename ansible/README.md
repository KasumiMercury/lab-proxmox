# Ansible Ops

## Inventory
- Generate: `task ansible:generate-inventory TF_ENV=<env>`
- File: `ansible/inventory/<env>.ini` with group `[<env>]`

## Inventory groups
- `scripts/generate_inventory.sh` writes `[<env>]` with every VM. VMs with a non-empty Terraform `role` are also listed in `[<env>_<role>]` (hyphens become underscores), e.g. `k8s_control_plane`, `k8s_worker`

## Playbooks
- `playbooks/setup.yml`: waits for SSH, then applies role `baseline` (Japanese locale, timezone, keyboard, bashtop)
- `playbooks/setup-k8s.yml`: imports `setup.yml`, installs MicroK8s on `[k8s]`, bootstraps `[k8s_control_plane]` (addons, kubeconfig to `artifacts/k8s.kubeconfig`), then joins `[k8s_worker]` one node at a time with `microk8s join ... --worker`
- `task ansible:run TF_ENV=<env>` uses `playbooks/setup-<env>.yml` when it exists, otherwise `playbooks/setup.yml`
- Roles live in `roles/` (`roles_path` in `ansible.cfg`). MicroK8s settings (`microk8s_channel`, `microk8s_addons`, `microk8s_cni`, `cilium_config_dir`, group names, timeouts) are in `roles/microk8s/defaults/main.yml`
- Cilium: every node gets host-side prep (`tasks/cilium_node.yml`, including `tasks/kube_proxy_disable.yml` when the shared values set `kubeProxyReplacement: true`; workers re-run it after join); the control plane deletes the Calico manifest, disables it for restarts, and, if the `cilium` DaemonSet does not exist yet, runs `microk8s helm3 install cilium --values cilium/values.yaml` with the chart from `cilium/version.yaml` (`tasks/cilium_control_plane.yml`). The pod CIDR in the values file is asserted against kube-proxy. Existing installations are left to ArgoCD

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

