variable "proxmox_url" {
  type        = string
  description = "URL to the Proxmox API"
  default     = "<proxmox url>"
}

variable "proxmox_username" {
  type        = string
  description = "Username when authenticating to Proxmox, including the realm."
  default     = "<proxmox api token id>"
}

variable "proxmox_token" {
  type        = string
  description = "Token for authenticating API calls."
  sensitive   = true
  default     = "<proxmox api token secret>"
}
