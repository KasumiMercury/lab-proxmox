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

variable "ip_address" {
  description = "IP address of the VM"
  type        = string
}

variable "disk_size" {
  description = "Size of the disk in GB"
  type        = number
  default     = 32
}

variable "username" {
  description = "Username"
  type        = string
}

variable "password" {
  description = "Password"
  type        = string
}
