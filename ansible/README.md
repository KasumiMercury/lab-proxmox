# Ansible Ops

## Inventory
- Generate: `task ansible:generate-inventory TF_ENV=<env>`
- File: `ansible/inventory/<env>.ini` with group `[<env>]`

## Playbooks
- `playbooks/setup-test.yml`
- `playbooks/setup-k8s.yml`
- `task ansible:run TF_ENV=<env>`

## SSH Auth
- `ANSIBLE_USE_PASSWORDS`: `true` or `false` (default: `false`) to include/exclude passwords in inventory

## Vault
- Create `.vault_pass.txt`: `task ansible:vault-passfile`
- Generate per-host vault vars: `task ansible:vault-hostvars-generate TF_ENV=<env>`
- Inventory without passwords: `ANSIBLE_USE_PASSWORDS=false task ansible:generate-inventory TF_ENV=<env>`

## Other
- `ANSIBLE_REMOTE_USER` overrides the remote user
- `ANSIBLE_PRIVATE_KEY_FILE=~/.ssh/id_ed25519 task ansible:test-connection TF_ENV=test` to verify the key path

