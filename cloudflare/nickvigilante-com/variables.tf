variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:Edit, DNS:Edit, Zone Settings:Edit on nickvigilante.com. Sourced from TF_VAR_cloudflare_api_token env var."
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID owning the nickvigilante.com zone."
  type        = string
  default     = "32467e77497570576f652f8946e632d2"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for nickvigilante.com."
  type        = string
  default     = "a38ad04ebe654b167f92db8b734ba898"
}
