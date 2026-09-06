# lab-proxmox

## Environment Variables
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`: S3 backend credentials
- `PM_API_URL`: e.g. `https://pve.example:8006/api2/json`
- `PM_API_TOKEN_ID` / `PM_API_TOKEN_SECRET`: Proxmox token pair (or use `PM_USER` / `PM_PASS`)

- `AWS_ENDPOINT_URL_S3`: S3-compatible endpoint (Cloudflare R2: `https://<account_id>.r2.cloudflarestorage.com`)

- `GPG_PASS`: used by `task -d terraform encrypt ...` / `task -d terraform decrypt ...`; 空なら実行時に対話で入力
- `ANSIBLE_PRIVATE_KEY_FILE`, `ANSIBLE_VAULT_PASSWORD_FILE`, `ANSIBLE_REMOTE_USER`: override defaults when running Ansible tasks

## Workflow
1. `task tf:decrypt -- terraform/environments/test` (first time / after a pull that changed `*.gpg`)
2. `task tf:plan TF_ENV=test`
3. `task tf:apply TF_ENV=test`
4. `task ans:inventory TF_ENV=test`
5. `task ans:ping TF_ENV=test`
6. `task ans:run TF_ENV=test`
7. `task tf:destroy TF_ENV=test`

`task deploy TF_ENV=test` runs steps 3, 4 and 6 in one go. Every Terraform-backed task depends on `tf:init`, which runs once per invocation.

Ansible tasks (`ans:ping`, `ans:run`, `ans:setup`, `deploy`) also depend on `ssh:agent`, which makes sure the VM SSH key is loaded in an ssh-agent:
- If the shell already has an agent (`SSH_AUTH_SOCK`), the key is added there. Otherwise an agent is started on a fixed socket (`~/.ssh/lab-proxmox-agent.sock`) that all tasks share, so the passphrase is asked once per boot, not per task
- Key path: `SSH_KEY_FILE` (default `~/.ssh/id_ed25519`; `ANSIBLE_PRIVATE_KEY_FILE` is honored as well). Put the matching `.pub` next to it, or the task derives it once
- `task ssh:agent-stop` stops the fixed-socket agent. Skipped automatically when `ANSIBLE_USE_PASSWORDS=true`

Short aliases (`task --list` shows all): `tf:init` `tf:plan` `tf:apply` `tf:destroy` `tf:output` `tf:passwords` `tf:encrypt` `tf:decrypt` `ans:inventory` `ans:ping` `ans:run` `ans:setup` `ans:vault-hostvars` `ssh:key` `pve:snippet`

## Kubernetes (k8s environment)
`task deploy TF_ENV=k8s` creates the three VMs and builds a MicroK8s cluster: `k8s-hod` is the control plane, `k8s-netzach` and `k8s-yesod` are workers.
- Roles come from `role` in `terraform/environments/k8s/k8s.auto.tfvars` (`control-plane` / `worker`) and become the inventory groups `k8s_control_plane` / `k8s_worker`
- Playbook: `ansible/playbooks/setup-k8s.yml` (baseline for all VMs, then role `microk8s`). Channel and addons are set in `ansible/roles/microk8s/defaults/main.yml` (default `1.36/stable`, addon `dns`)
- CNI is Cilium, bootstrapped with the bundled `microk8s helm3` on the control plane before workers join (the default Calico is removed). Ansible installs it only on a fresh cluster and never touches an existing installation; every later change (version, custom builds, features) is managed by ArgoCD. Set `microk8s_cni: calico` to keep the MicroK8s default
- Cilium runs as kube-proxy replacement from the start (`kubeProxyReplacement: true`, API via `127.0.0.1:16443` on every node). MicroK8s has no switch for kube-proxy, so Ansible starts it with `--init-only` (it applies its node sysctls, programs no rules and exits; kubelite keeps running), removes the rules left by the first run, and rolls the change back automatically if kubelite does not stay up
- Cilium chart pin and values live in `cilium/` (`version.yaml`, `values.yaml`). That directory is self-contained so it can become a git submodule shared with the ArgoCD repo; see `cilium/README.md` for the contract
- Node-to-node ports: 16443 (API), 25000 (join), 10250 (kubelet), 8472/udp (Cilium VXLAN), 4240 (Cilium health). The VMs' NICs have the Proxmox firewall flag set, so keep the VM firewall disabled or allow these
- Control plane VM has 8192 MB (`memory` in `k8s.auto.tfvars`), workers 4096 MB
- The kubeconfig is fetched to `ansible/artifacts/k8s.kubeconfig` (gitignored): `export KUBECONFIG=$PWD/ansible/artifacts/k8s.kubeconfig && kubectl get nodes`
- Re-running the playbook is safe: nodes already in the cluster are not joined again

## Terraform Layout
- `terraform/shared/`: backend, providers, root module (`main.tf`), variables. Shared by every environment
- `terraform/environments/<env>/`: symlinks to `shared/*.tf` plus `<env>.auto.tfvars`, `<env>_credential.auto.tfvars.json(.gpg)`, `.terraform.lock.hcl`
- State key is set at init: `terraform init -backend-config="key=proxmox/<env>/terraform.tfstate"` (`task terraform:init` does this)
- Backend is Cloudflare R2 (S3-compatible); endpoint and credentials come from `AWS_*` env vars
- To add an environment: create the directory, symlink the four `shared/*.tf` files, add tfvars. On Windows enable `git config core.symlinks true` before checkout

## Settings
- `TF_ENV`: environment name (`test`, `k8s`). Default `test`
- `ANSIBLE_USE_PASSWORDS`: write passwords into inventory (default `false`)
- `SSH_KEY_FILE` / `ANSIBLE_PRIVATE_KEY_FILE`: SSH private key loaded by `ssh:agent`, e.g. `~/.ssh/id_ed25519`
- `ANSIBLE_VAULT_PASSWORD_FILE`: path to vault password file, e.g. `.vault_pass.txt`
- Inventory output: `ansible/inventory/<env>.ini`
- Playbook: `ansible/playbooks/setup.yml`. If `ansible/playbooks/setup-<env>.yml` exists it is used instead (override with `ANSIBLE_PLAYBOOK=...`)
- Cloud-init: Proxmox generates user-data from Terraform (`ciuser` / `cipassword` / `sshkeys`). On Ubuntu cloud images that user gets passwordless sudo and key-only SSH by default, so no snippet is needed for the default (key-based) Ansible flow
- To allow SSH password auth (needed for `ANSIBLE_USE_PASSWORDS=true`), attach `ansible/cloudinit-snippets/password-auth.yml` as vendor-data. Upload it once with `task pve:snippet HOST=user@hod` (goes to the shared NFS storage `strix0`, which has the `snippets` content type enabled, so all nodes see it), then set in `terraform/environments/<env>/*.auto.tfvars`:
  ```hcl
  cloudinit_vendor_snippet = "strix0:snippets/password-auth.yml"
  ```


## SSH
- `ANSIBLE_SSH_ARGS`: disable host key checking
  ```bash
  export ANSIBLE_SSH_ARGS='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
  ```

## Secrets
- Keep decrypted tfvars outside git; commit only `*.tfvars.json.gpg` (`*.tfvars.json` is gitignored)
- Encrypt: `task -d terraform encrypt -- terraform/environments/<env>` → `*.tfvars.json.gpg`
- Decrypt: `task -d terraform decrypt -- terraform/environments/<env>` → `*.tfvars.json` (0600, overwrites existing)
- Single file: `task -d terraform gpg-decrypt-file -- terraform/environments/k8s/k8s_credential.auto.tfvars.json.gpg`
- `task ansible:vault-passfile` → `.vault_pass.txt` (gitignored)
- `task ansible:vault-hostvars-generate TF_ENV=test` → encrypted `ansible/inventory/host_vars/<vm>/vault.yml`
- No-password inventory: `ANSIBLE_USE_PASSWORDS=false task ansible:generate-inventory TF_ENV=test`
