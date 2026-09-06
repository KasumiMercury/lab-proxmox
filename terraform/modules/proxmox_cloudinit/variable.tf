variable "target_node" {
  description = "Proxmox node to deploy the VM on"
  type        = string
}

variable "vmid" {
  description = "VM ID for the new VM (must be unique within the Proxmox cluster)"
  type        = number
  validation {
    condition     = var.vmid >= 100 && var.vmid <= 999999999
    error_message = "VMID must be between 100 and 999999999."
  }
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
}


/*
  # Optional variables
  # Hardware configuration
*/
variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "cpu_type" {
  description = "Proxmox CPU type (e.g. x86-64-v2-AES for live migration compatibility, host for full CPU features)"
  type        = string
  default     = "x86-64-v2-AES"
}

variable "memory" {
  description = "Amount of memory in MB"
  type        = number
  default     = 4096
}

/*
  # Network configuration
*/
variable "ip_address" {
  description = "IP address of the VM (CIDR notation without mask, e.g., 192.168.1.10)"
  type        = string
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.ip_address))
    error_message = "IP address must be a valid IPv4 address format (e.g., 192.168.1.10)."
  }
}

variable "gateway" {
  description = "Gateway IP address for the VM network"
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
  description = "DNS server for the VM"
  type        = string
  default     = "8.8.8.8"
}

variable "network_bridge" {
  description = "Network bridge to use"
  type        = string
  default     = "vmbr0"
}

variable "network_tag" {
  description = "VLAN tag for the network interface"
  type        = number
  default     = 0
}

/*
  # Optional variables
  # Disk configuration
*/
variable "disk_size" {
  description = "Size of the disk in GB"
  type        = number
  default     = 32
}

variable "disk_storage" {
  description = "Storage pool for the primary disk"
  type        = string
  default     = "local-lvm"
}

/*
  # User configuration
*/
variable "username" {
  description = "Username"
  type        = string
  sensitive   = true
}

variable "password_length" {
  description = "Length of the generated password (minimum 8 characters recommended)"
  type        = number
  validation {
    condition     = var.password_length >= 8 && var.password_length <= 128
    error_message = "Password length must be between 8 and 128 characters."
  }
}

variable "ssh_key" {
  description = "SSH public key"
  type        = string
  sensitive   = true
}

/*
  # Cloud-init configuration
  # Commonly used for cloud-init configuration
*/
variable "cloudinit_storage" {
  description = "Storage for cloud-init disk"
  type        = string
}

variable "template" {
  description = "Template to clone from"
  type        = string
}

/*
  # Optional: Cloud-init custom snippet
  # Example: "user=local:snippets/ansible-user.yml"
  # Use this to enforce passwordless sudo and disable SSH password auth.
*/
variable "cicustom" {
  description = "Cloud-init custom snippet reference (e.g., user=local:snippets/ansible-user.yml)"
  type        = string
  default     = null
}
