variable "target_node" {
  description = "Proxmox node to deploy the container on"
  type        = string
}

variable "vmid" {
  description = "VM ID for the new container (must be unique within the Proxmox cluster)"
  type        = number
  validation {
    condition     = var.vmid >= 100 && var.vmid <= 999999999
    error_message = "VMID must be between 100 and 999999999."
  }
}

variable "hostname" {
  description = "Hostname of the container"
  type        = string
}

variable "ostemplate" {
  description = "Container template volume (e.g. strix0:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst)"
  type        = string
}

/*
  # Optional variables
  # Hardware configuration
*/
variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Amount of memory in MB"
  type        = number
  default     = 512
}

variable "swap" {
  description = "Amount of swap in MB"
  type        = number
  default     = 512
}

variable "onboot" {
  description = "Start the container when the node boots"
  type        = bool
  default     = true
}

variable "protection" {
  description = "Proxmox protection flag (blocks removal of the container and its disks)"
  type        = bool
  default     = true
}

/*
  # Disk configuration
*/
variable "rootfs_storage" {
  description = "Storage pool for the root filesystem"
  type        = string
  default     = "local-lvm"
}

variable "rootfs_size" {
  description = "Size of the root filesystem in GB"
  type        = number
  default     = 8
}

variable "mountpoints" {
  description = "Storage backed mount points, assigned to mp0, mp1, ... in order"
  type = list(object({
    storage = string
    size    = number
    mp      = string
    backup  = optional(bool, false)
  }))
  default = []
}

/*
  # Network configuration
*/
variable "ip_address" {
  description = "IP address of the container (CIDR notation without mask, e.g., 192.168.1.10)"
  type        = string
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.ip_address))
    error_message = "IP address must be a valid IPv4 address format (e.g., 192.168.1.10)."
  }
}

variable "gateway" {
  description = "Gateway IP address for the container network"
  type        = string
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.gateway))
    error_message = "Gateway must be a valid IPv4 address format (e.g., 192.168.1.1)."
  }
}

variable "ip_prefix_length" {
  description = "Network prefix length for ip_address (e.g., 24)"
  type        = number
  default     = 24
  validation {
    condition     = var.ip_prefix_length >= 1 && var.ip_prefix_length <= 32
    error_message = "Prefix length must be between 1 and 32."
  }
}

variable "nameserver" {
  description = "DNS server for the container"
  type        = string
  default     = "8.8.8.8"
}

variable "network_bridge" {
  description = "Network bridge to use"
  type        = string
  default     = "vmbr0"
}

variable "network_tag" {
  description = "VLAN tag for the network interface (0 = untagged)"
  type        = number
  default     = 0
}

/*
  # Credentials
*/
variable "password_length" {
  description = "Length of the generated root password (minimum 8 characters recommended)"
  type        = number
  validation {
    condition     = var.password_length >= 8 && var.password_length <= 128
    error_message = "Password length must be between 8 and 128 characters."
  }
}

variable "ssh_key" {
  description = "SSH public keys for root (one per line)"
  type        = string
  sensitive   = true
}
