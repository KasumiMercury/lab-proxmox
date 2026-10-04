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

Short aliases (`task --list` shows all): `tf:init` `tf:plan` `tf:apply` `tf:destroy` `tf:output` `tf:passwords` `tf:encrypt` `tf:decrypt` `ans:inventory` `ans:ping` `ans:run` `ans:setup` `ans:vault-hostvars` `ssh:key` `pve:snippet` `argocd:password` `argocd:port-forward`

## Kubernetes (k8s environment)
`task deploy TF_ENV=k8s` creates the three VMs and builds a MicroK8s cluster: `k8s-hod` is the control plane, `k8s-netzach` and `k8s-yesod` are workers.
- Roles come from `role` in `terraform/environments/k8s/k8s.auto.tfvars` (`control-plane` / `worker`) and become the inventory groups `k8s_control_plane` / `k8s_worker`
- Playbook: `ansible/playbooks/setup-k8s.yml` (baseline for all VMs, then role `microk8s`). Channel and addons are set in `ansible/roles/microk8s/defaults/main.yml` (default `1.36/stable`, addon `dns`)
- CNI is Cilium, bootstrapped with the bundled `microk8s helm3` on the control plane before workers join (the default Calico is removed). Ansible installs it only on a fresh cluster and never touches an existing installation; every later change (version, custom builds, features) is managed by ArgoCD. Set `microk8s_cni: calico` to keep the MicroK8s default
- Cilium runs as kube-proxy replacement from the start (`kubeProxyReplacement: true`, API via `127.0.0.1:16443` on every node). MicroK8s has no switch for kube-proxy, so Ansible starts it with `--init-only` (it applies its node sysctls, programs no rules and exits; kubelite keeps running) and rolls the change back automatically if kubelite does not stay up
- Every node first runs as a standalone MicroK8s with Calico and kube-proxy, which leaves the `vxlan.calico` device, Calico routes and iptables rules (legacy and nft) behind. After the workers join, Ansible checks each node in turn and reboots it when any of these are found
- Cilium has Gateway API support enabled (`gatewayAPI.enabled` in `cilium/values.yaml`). The Gateway API CRDs (version in `cilium/gateway-api.yaml`) are applied right before Cilium, because the operator only enables it when they exist at startup
- Cilium chart pin and values live in `cilium/` (`version.yaml`, `values.yaml`), a git submodule of [lab-cilium](https://github.com/KasumiMercury/lab-cilium) shared with the ArgoCD repo; run `git submodule update --init` after cloning. See `cilium/README.md` for the contract
- Node-to-node ports: 16443 (API), 25000 (join), 10250 (kubelet), 8472/udp (Cilium VXLAN), 4240 (Cilium health). The VMs' NICs have the Proxmox firewall flag set, so keep the VM firewall disabled or allow these
- Control plane VM has 8192 MB (`memory` in `k8s.auto.tfvars`), workers 4096 MB
- The VMs use the CPU type `x86-64-v3` (supported by all three hosts); some images (ceph-csi 3.18) need it
- The nodes run the noble HWE kernel (`microk8s_kernel_package`, 7.0): Ceph 19.2.6+ issues aes256k cephx keys, which the kernel RBD client only supports from Linux 7.0. A node is rebooted (one at a time, after the workers joined) when a newer kernel is installed than the one running
- Per-VM options in `virtual_machines` (`<env>.auto.tfvars`): `cores`, `cpu_type` (default `x86-64-v2-AES`; `host` exposes the full CPU), `memory`, `disk_size`, `disk_storage`, `network_bridge`, `network_tag`, `role`, `power_state` (`running` by default; `stopped` keeps the VM shut down and every apply stops it, e.g. the test VM)
- The kubeconfig is fetched to `ansible/artifacts/k8s.kubeconfig` (gitignored): `export KUBECONFIG=$PWD/ansible/artifacts/k8s.kubeconfig && kubectl get nodes`
- Re-running the playbook is safe: nodes already in the cluster are not joined again
- ArgoCD is bootstrapped last (role `argocd`, chart `argo/argo-cd` 10.8.1 = Argo CD v3.5.2) only when it is absent; afterwards it is managed from the ArgoCD repository. The root Application is applied with `task bootstrap` in the ArgoCD repository. `task argocd:password TF_ENV=k8s` prints the initial admin password, `task argocd:port-forward TF_ENV=k8s` exposes the UI at `http://localhost:8080`. On the tailnet it is at `https://argocd.<tailnet>.ts.net` (Tailscale Ingress in the ArgoCD repository, which terminates TLS; argocd-server runs with `server.insecure`)

### Setup
Prerequisites:
- [lab-argo](https://github.com/KasumiMercury/lab-argo): Argo CD reads it from GitHub, not from a local checkout. Clone it next to this repository (`../lab-argo`) with `--recurse-submodules`
- The NAS export `192.168.110.5:/nfs/k8s` allows the k8s VM subnet `192.168.110.0/24` with `no_root_squash` (backs the `nfs-csi` StorageClass in lab-argo)
- The VM SSH key is the one in `credentials_vm.ssh_key` (loaded by `ssh:agent`), and the environment variables above are set

Steps (from this repository unless noted):
1. `git submodule update --init` (checks out `cilium/`; the playbook reads the Cilium pin and values from it)
2. `task tf:decrypt -- terraform/environments/k8s` (first time / after `*.gpg` changed)
3. `task tf:plan TF_ENV=k8s`: expect the three VMs and their passwords to be added
4. `task deploy TF_ENV=k8s`: creates the VMs, generates `ansible/inventory/k8s.ini` and runs `setup-k8s.yml` (MicroK8s, Cilium, worker joins, Argo CD). The kubeconfig lands in `ansible/artifacts/k8s.kubeconfig`
5. Check the cluster:
   ```bash
   export KUBECONFIG=$PWD/ansible/artifacts/k8s.kubeconfig
   kubectl get nodes -o wide                                  # all three Ready
   kubectl -n kube-system exec ds/cilium -- cilium-dbg status --brief
   kubectl -n kube-system exec ds/cilium -- cilium-dbg status | grep KubeProxyReplacement   # True
   ```
6. In lab-argo: `task bootstrap` (applies the root app-of-apps `bootstrap/root.yaml`; lab-argo's Taskfile uses the same kubeconfig by default). Watch with `task argocd:port-forward TF_ENV=k8s` and `task argocd:password TF_ENV=k8s`. The components sync in waves: cilium and argocd (adopted), sealed-secrets and csi-driver-nfs, tailscale, kube-prometheus-stack
7. In lab-argo, once `sealed-secrets` is Healthy: `task seal:tailscale` and `task seal:grafana`, then commit and push. The Tailscale operator (and everything after it) waits for these Secrets

If a step fails, re-running `task ans:run TF_ENV=k8s` is safe. Cilium and Argo CD are only installed when absent, so a broken first install has to be removed by hand (`microk8s helm3 uninstall ...`) before re-running.

## Samba (samba environment)
`task deploy TF_ENV=samba` creates the unprivileged LXC `gnosis` (VMID 101) on yesod and sets up Samba (`ansible/playbooks/setup-samba.yml`, role `samba`).
- The share `[shared]` is `/mnt/monad`, a storage backed mount point (`mp0`) on `monad`, yesod's local HDD, so the container cannot move to another node
- Containers are declared in `containers` (`<env>.auto.tfvars`) with credentials in `credentials_ct` (`<env>_credential.auto.tfvars.json`). They log in as `root` with the keys in `ssh_key`
- Destroying a container deletes every volume it owns, share data included. The LXC module sets `prevent_destroy` and the Proxmox `protection` flag; remove both on purpose before tearing one down
- `ostemplate`, `password` and `ssh_public_keys` are only applied at creation (later changes are ignored)
- Mount points are excluded from vzdump backups unless `backup = true` is set in `mountpoints`
- Samba passwords and the machine SID come from `passdb.tdb` / `secrets.tdb` of the old server, placed in `ansible/artifacts/samba/` (gitignored). The role copies them when present
- `task ans:run TF_ENV=samba -- -e samba_services_enabled=false` configures everything but keeps smbd/nmbd/wsdd2 stopped (used while the old server is still up). Arguments after `--` go to `ansible-playbook`

## Monitoring (Proxmox nodes and strix)
`task monitoring:setup` runs `ansible/playbooks/setup-monitoring.yml` against the static inventory `ansible/inventory/hosts.yml` (Proxmox nodes as root, the NAS strix as `mercury` over Tailscale; it asks for strix's sudo password).
- strix (role `monitoring_server`): Docker Compose project `/srv/monitoring` with VictoriaMetrics (retention 1y, listening on `192.168.110.5:8428` and `127.0.0.1:8428`), Grafana and a Tailscale container. Grafana listens on localhost only and is published by the Tailscale container as its own tailnet node, `https://pve-grafana.<tailnet>.ts.net` (`grafana` is the k8s Grafana). Each service on strix gets its own Tailscale container, so names do not collide and the host's tailscaled (SSH) is left alone. The VictoriaMetrics data source is provisioned. The initial admin password is generated into `ansible/artifacts/strix-grafana-admin-password` (gitignored) and only applies on Grafana's first start
- The Tailscale containers log in with an OAuth client (scope `auth_keys`, tag `tag:strix`) whose secret is `vault_tailscale_oauth_client_secret` in `ansible/inventory/host_vars/strix/vault.yml` (ansible-vault; `task ansible:vault-passfile` creates `.vault_pass.txt`, which `task monitoring:setup` passes on). The tailnet policy needs `tag:strix` in `tagOwners`. Node state is kept in `/srv/monitoring/tailscale/state`, so the secret is only used for the first login
- Proxmox nodes (role `pve_monitoring`): node_exporter (Debian package, `127.0.0.1:9100`), prometheus-pve-exporter (PyPI venv in `/opt/prometheus-pve-exporter`, `127.0.0.1:9221`) and vmagent (`127.0.0.1:8429`). vmagent scrapes the local exporters every 30s and pushes to strix. Push, because the router routes 192.168.20.0/24 → strix but not strix → 192.168.20.0/24. While strix is unreachable vmagent buffers up to 1 GiB per node in `/var/lib/vmagent` and sends it later
- The exporter uses the API user `prometheus@pve` (PVEAuditor on `/`) with token `exporter`. The secret is shown only when the token is created, so the role writes it to `/etc/prometheus/pve.yml` on every node in the same run. If a node lacks that file later (e.g. a new node), the role fails: remove the token (`pveum user token remove prometheus@pve exporter`) and re-run to issue a new one everywhere
- Ceph: the role enables the mgr `prometheus` module and every node with a mgr (yesod, netzach) scrapes it locally. A standby mgr answers `/metrics` with an empty 200, so only the active one yields data. Ceph series carry `instance="ceph"` regardless of which mgr is active; `up{job="ceph"}` keeps a `node` label to tell the two targets apart
- PVE cluster metrics (guests, storage) come from every node's exporter (`cluster=1`), distinguished by `instance`
- Versions of the images, vmagent and prometheus-pve-exporter are in the role defaults with a `# renovate: datasource=... depName=...` comment above them, picked up by the regex manager in `renovate.json`. VictoriaMetrics and vmagent are grouped into one PR. The dashboard revisions in `grafana_dashboards` are tracked through a custom datasource for the grafana.com API (keep the `{ id: ..., revision: ..., file: ...` order the regex expects). The same `# renovate:` comments work in any role defaults (e.g. `argocd_chart_version`). vmagent's archive is checked against the release's `_checksums.txt`, so bumping the version is enough
- The mgr also exports daemon perf counters (`exclude_perf_counters=false`; since Reef they are left to ceph-exporter, which pveceph does not deploy), for the OSD I/O panels
- Dashboards (`grafana_dashboards` in the role defaults) are downloaded from grafana.com at pinned revisions and provisioned read-only into the "Proxmox" folder: 10347 Proxmox via Prometheus, 1860 Node Exporter Full, 2842 Ceph Cluster. Dashboards with an import-time data source input (`datasource_input`) get it replaced by the VictoriaMetrics data source

## Zabbix (strix)
`task zabbix:setup` runs `ansible/playbooks/setup-zabbix.yml` (role `zabbix_server`) against strix in the static inventory `ansible/inventory/hosts.yml` (asks for strix's sudo password).
- Docker Compose project `/srv/zabbix`: TimescaleDB (PostgreSQL 17), Zabbix server, frontend (nginx, `127.0.0.1:8080`), agent 2 and a Tailscale container that publishes the frontend as `https://zabbix.<tailnet>.ts.net` (same OAuth client and `tag:strix` as Grafana). The server creates the schema on its first start and, with `ENABLE_TIMESCALEDB=true`, turns history and trends into hypertables. timescaledb-tune sizes PostgreSQL for `timescaledb_tune_memory` (1 GB) when the database is created; `max_connections` is overridden on the command line (`timescaledb_max_connections`, 100), because the tune caps it at 25 for that size and the Zabbix server alone needs about 30
- Secrets in `ansible/inventory/host_vars/strix/vault.yml`: `vault_zabbix_db_password`, `vault_zabbix_admin_password` (set on `Admin` through the API on the first run, when `Admin` / `zabbix` still works) and `vault_zabbix_snmp_community` (global secret macro `{$SNMP_COMMUNITY}`)
- The built-in host "Zabbix server" is pointed at the agent container (`zabbix-agent`). It sees the container's file systems and interfaces, not strix's
- Network devices are `zabbix_snmp_hosts` in the role defaults (SNMPv2c, host group "Network devices", templates shipped with Zabbix). The role creates missing hosts and keeps their SNMP interface, group and templates in line; anything else set in the UI is kept. The Cisco 891FJ is polled at `192.168.110.1` (template "Cisco IOS by SNMP"). The AT-x210-16GT is polled at its management address `192.168.10.2` (template "Network Generic Device by SNMP"). The 891FJ runs a zone-based firewall (Vlan100 = zone SERVER, Vlan10 = MANAGEMENT) and only the zone-pair SERVER-to-MANAGEMENT (ACL `ACL-SERVER-TO-MGMT-MONITOR`: SNMP and ping from 192.168.110.5 to 192.168.10.2) lets strix reach the switch; the router itself is in the self zone and answers directly
- Own templates in `ansible/roles/zabbix_server/files/templates` (`zabbix_own_templates`) are imported through the API when `configuration.importcompare` reports a difference. "Cisco ENVMON temperature state by SNMP" covers the 891FJ: it has no temperature sensor values (`ciscoEnvMonPresent` = cAccessMon; the CISCO-ENVMON-MIB temperature rows have empty descriptions and value 0, the entity sensor MIBs are empty, `show environment` only says "normal"), so "Cisco IOS by SNMP" finds no temperature. The template discovers the rows of `ciscoEnvMonTemperatureState` and raises Warning / High / Disaster / Average for warning / critical / shutdown / notFunctioning
- SNMP on the devices is configured by hand, read-only and limited to strix, with the community from the vault (`ansible-vault view inventory/host_vars/strix/vault.yml`):
  - Cisco IOS: `access-list 99 permit 192.168.110.5` / `snmp-server community <community> RO 99`
  - AlliedWare Plus: `snmp-server` / `snmp-server community <community> ro <access-list>` with a standard access list that permits only 192.168.110.5
- Versions: `timescaledb_version` and `zabbix_version` in the role defaults (`# renovate:` comments). Zabbix tags are `ubuntu-x.y.z` (regex versioning in `renovate.json`). TimescaleDB updates wait for approval on the Dependency Dashboard, because Zabbix only accepts the TimescaleDB versions in its requirements (7.4: 2.13–2.29); the PostgreSQL major in the tag (`-pg17`) cannot be changed in place

## Terraform Layout
- `terraform/shared/`: backend, providers, root module (`main.tf`), variables. Shared by every environment
- `terraform/environments/<env>/`: symlinks to `shared/*.tf` plus `<env>.auto.tfvars`, `<env>_credential.auto.tfvars.json(.gpg)`, `.terraform.lock.hcl`
- VMs get the Proxmox tags `<env>` (directory name), their `role` (if set) and `terraform`
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
