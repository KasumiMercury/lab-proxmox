terraform {
  required_version = ">= 1.11"
  backend "s3" {
    bucket                      = "terraform"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    use_lockfile                = true
  }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc04"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}