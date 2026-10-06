locals {
  controlplane = one([for k, n in var.nodes : merge(n, { key = k }) if n.role == "controlplane"])
  endpoint     = "https://${local.controlplane.ip_address}:6443"
  installer    = "factory.talos.dev/nocloud-installer/${var.schematic_id}:${var.talos_version}"

  controlplane_patch = file("${path.module}/patches/controlplane.yaml")
}

resource "proxmox_vm_qemu" "node" {
  for_each = var.nodes

  os_type = "cloud-init"
  clone   = var.template
  # A linked clone would stay on the template's NFS storage (telmate then fails to place the disk on local-lvm)
  full_clone = true
  boot       = "order=scsi0"
  # Talos docs: VirtIO SCSI single hangs the bootstrap
  scsihw = "virtio-scsi-pci"

  vmid        = each.value.vmid
  name        = each.value.vm_name
  target_node = each.value.target_node
  tags        = join(";", sort([var.cluster_name, each.value.role, "terraform"]))

  # qemu-guest-agent comes from the schematic's system extension
  agent = 1

  # Talos has no memory hotplug; the docs recommend turning ballooning off
  memory  = each.value.memory
  balloon = 0

  # Talos (nocloud) reads only the network config from the cloud-init drive; the machine config is applied over its API
  ipconfig0  = "ip=${each.value.ip_address}/${var.ip_prefix_length},gw=${var.gateway}"
  nameserver = var.nameserver

  cpu {
    cores = each.value.cores
    type  = each.value.cpu_type
  }

  serial {
    id   = 0
    type = "socket"
  }

  disks {
    ide {
      ide1 {
        cloudinit {
          storage = var.cloudinit_storage
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          storage = each.value.disk_storage
          size    = "${each.value.disk_size}G"
        }
      }
    }
  }

  network {
    id       = 0
    bridge   = each.value.network_bridge
    tag      = each.value.network_tag
    model    = "virtio"
    firewall = true
  }

  power_state = "running"

  # Same workaround as modules/proxmox_cloudinit (provider reads an unset block back as -1s)
  startup_shutdown {
    order            = -1
    shutdown_timeout = -1
    startup_delay    = -1
  }
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_machine_configuration" "this" {
  for_each = var.nodes

  cluster_name       = var.cluster_name
  cluster_endpoint   = local.endpoint
  machine_type       = each.value.role
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  config_patches = concat(
    [templatefile("${path.module}/patches/common.yaml.tftpl", {
      installer      = local.installer
      hostname       = each.value.vm_name
      pod_subnet     = var.pod_subnet
      service_subnet = var.service_subnet
    })],
    each.value.role == "controlplane" ? [local.controlplane_patch] : [],
    var.config_patches,
  )
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [local.controlplane.ip_address]
  nodes                = [for n in values(var.nodes) : n.ip_address]
}

# The clone boots in maintenance mode; the first apply installs Talos to the disk and reboots
resource "talos_machine_configuration_apply" "this" {
  for_each = var.nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration
  node                        = each.value.ip_address

  depends_on = [proxmox_vm_qemu.node]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.controlplane.ip_address

  depends_on = [talos_machine_configuration_apply.this]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.controlplane.ip_address

  depends_on = [talos_machine_bootstrap.this]
}
