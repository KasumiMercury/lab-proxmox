# Ansible Ops

## Inventory
- Generate: `task ansible:generate-inventory TF_ENV=<env>`
- File: `ansible/inventory/<env>.ini` with group `[<env>]`

## Playbooks
- `playbooks/setup.yml`: waits for SSH, then applies role `baseline` (Japanese locale, timezone, keyboard, bashtop)
- `task ansible:run TF_ENV=<env>` uses `playbooks/setup-<env>.yml` when it exists, otherwise `playbooks/setup.yml`
- Roles live in `roles/` (`roles_path` in `ansible.cfg`)

## Cloud-init snippets (`cloudinit-snippets/`)
- Terraform owns the user-data: Proxmox generates it from `ciuser` / `cipassword` / `sshkeys`. Snippets are attached as vendor-data only (`cloudinit_vendor_snippet` in tfvars), so they add policy without touching the user
- `password-auth.yml`: enables SSH password auth (`ssh_pwauth: true`, root login stays disabled). Required for `ANSIBLE_USE_PASSWORDS=true`
- Without a snippet the Terraform-managed user has key-only SSH and passwordless sudo (Ubuntu cloud image defaults)
- Upload: `task proxmox:upload-snippet HOST=user@pve [SRC=...] [DEST=...]`

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

