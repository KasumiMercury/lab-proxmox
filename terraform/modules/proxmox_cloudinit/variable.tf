variable "target_node" {
  description = "Proxmox node to deploy the VM on"
  type        = string
}

variable "vmid" {
  description = "VM ID for the new VM"
  type        = number
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

variable "memory" {
  description = "Amount of memory in MB"
  type        = number
  default     = 4096
}

/*
  # Network configuration
*/
variable "ip_address" {
  description = "IP address of the VM"
  type        = string
}

variable "gateway" {
  description = "Gateway for the VM"
  type        = string
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

/*
  # User configuration
*/
variable "username" {
  description = "Username"
  type        = string
}

variable "password" {
  description = "Password"
  type        = string
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
