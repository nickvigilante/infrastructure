terraform {
  required_version = ">= 1.10.0"

  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.18"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.5"
    }
  }
}
