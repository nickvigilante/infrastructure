output "tailnet_global_nameserver" {
  description = "The Tailscale Global Nameserver IP this context configures."
  value       = var.homelab_dns_nameserver_ip
}

output "managed_repos" {
  description = "Names of the GitHub repositories under management."
  value       = sort(keys(github_repository.managed))
}

output "protected_repos" {
  description = "Names of repos with branch protection on `main`."
  value       = sort(keys(github_branch_protection.main))
}
