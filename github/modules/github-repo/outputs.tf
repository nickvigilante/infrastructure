output "repo_name" {
  description = "Name of the managed repository."
  value       = github_repository.this.name
}

output "node_id" {
  description = "GraphQL node ID of the managed repository."
  value       = github_repository.this.node_id
}

output "protected" {
  description = "Whether this repo has a branch-protection ruleset on its default branch."
  value       = var.settings.protect_main
}
