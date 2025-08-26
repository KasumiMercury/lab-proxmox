provider "cloudflare" {
  # token pulled from $CLOUDFLARE_API_TOKEN
}

provider "proxmox" {
  pm_tls_insecure = true
  # Proxmox API credentials expected via environment variables:
  # PM_API_URL, PM_USER, PM_PASS (or PM_API_TOKEN_ID and PM_API_TOKEN_SECRET)
}