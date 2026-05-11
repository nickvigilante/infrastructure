variable "tailscale_oauth_client_id" {
  description = "OAuth client ID for the opentofu-homelab Tailscale integration."
  type        = string
  sensitive   = true
}

variable "tailscale_oauth_client_secret" {
  description = "OAuth client secret for the opentofu-homelab Tailscale integration."
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub user/org whose repos this context manages."
  type        = string
  default     = "nickvigilante"
}

variable "github_app_id" {
  description = "GitHub App ID (from the App settings page)."
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App installation ID (from the install URL once installed on the account)."
  type        = string
  sensitive   = true
}

variable "github_app_pem_file" {
  description = "Filesystem path to the GitHub App private-key PEM file (chmod 600, out of repo)."
  type        = string
  sensitive   = true
}

variable "homelab_dns_nameserver_ip" {
  description = "Tailscale IP of the node running Pi-hole. Used as the tailnet's Global Nameserver."
  type        = string
  default     = "100.92.2.25" # gandalf
}
