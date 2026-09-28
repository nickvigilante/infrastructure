variable "github_app_id" {
  description = "GitHub App ID (from the App settings page). Same App used by homelab/."
  type        = string
  sensitive   = true
}

variable "github_app_pem_file" {
  description = "Filesystem path to the GitHub App private-key PEM file (chmod 600, out of repo)."
  type        = string
  sensitive   = true
}

variable "github_owner_personal" {
  description = "Personal GitHub username this context manages repos for."
  type        = string
  default     = "nickvigilante"
}

variable "github_owner_klavyn" {
  description = "The klavyn GitHub organization this context manages repos for."
  type        = string
  default     = "klavyn"
}

variable "github_app_installation_id_personal" {
  description = "GitHub App installation ID for the personal (github_owner_personal) account. Same installation homelab/ already uses."
  type        = string
  sensitive   = true
}

variable "github_app_installation_id_klavyn" {
  description = "GitHub App installation ID for the klavyn org installation. Empty until the App is installed there (see docs/plans/2026-09-27-github-config-management.md, Chunk E) -- harmless until repos/klavyn/ has files that actually use the klavyn provider."
  type        = string
  sensitive   = true
  default     = ""
}
