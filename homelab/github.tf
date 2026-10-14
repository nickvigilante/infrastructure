# Repos and their vulnerability alerts now live in github/ (one file per
# repo). These blocks drop them from this context's state without calling
# GitHub, so nothing is disabled or deleted -- see
# docs/plans/2026-09-27-github-config-management.md, Chunk C.
removed {
  from = github_repository.managed

  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_vulnerability_alerts.alerts

  lifecycle {
    destroy = false
  }
}

removed {
  from = github_repository_environment.homelab_apply

  lifecycle {
    destroy = false
  }
}

data "github_repository" "classic_protected" {
  for_each = {
    for name, cfg in local.repos_resolved : name => cfg
    if cfg.protect_main
  }

  name = each.key
}

# Classic branch protection on `main` for every repo where protect_main = true.
# Transitional: github/ now adds a ruleset to each of these repos, and GitHub
# enforces the union of both. Delete this once the rulesets are verified
# (Chunk D), leaving the rulesets to protect `main` alone.
resource "github_branch_protection" "main" {
  for_each = {
    for name, cfg in local.repos_resolved : name => cfg
    if cfg.protect_main
  }

  repository_id                   = data.github_repository.classic_protected[each.key].node_id
  pattern                         = "main"
  enforce_admins                  = false # allow you to bypass in emergencies
  require_conversation_resolution = each.value.require_conversation_resolution
  require_signed_commits          = each.value.require_signed_commits
  required_linear_history         = each.value.require_linear_history
  allows_force_pushes             = false
  allows_deletions                = false

  required_pull_request_reviews {
    dismiss_stale_reviews           = each.value.dismiss_stale_reviews
    require_code_owner_reviews      = each.value.require_code_owner_reviews
    required_approving_review_count = each.value.required_approving_review_count
  }

  # Only emit required_status_checks block if there are checks to require —
  # an empty contexts list would still create the block and force a check.
  dynamic "required_status_checks" {
    for_each = length(each.value.required_status_check_contexts) > 0 ? [1] : []
    content {
      strict   = each.value.required_status_checks_strict
      contexts = each.value.required_status_check_contexts
    }
  }
}

# Actions secrets for the infrastructure repo so its CI plan workflow can run.
# Source values come from the same env vars the local user already exports.
# These stay here even though the repo object moved to github/: github-plan's
# CI has none of the Tailscale or AWS values, and importing a secret can't
# read its value back, so moving them would recreate every live secret.
resource "github_actions_secret" "tailscale_oauth_client_id" {
  repository  = "infrastructure"
  secret_name = "TAILSCALE_OAUTH_CLIENT_ID"
  value       = var.tailscale_oauth_client_id
}

resource "github_actions_secret" "tailscale_oauth_client_secret" {
  repository  = "infrastructure"
  secret_name = "TAILSCALE_OAUTH_CLIENT_SECRET"
  value       = var.tailscale_oauth_client_secret
}

# Storj S3 credentials for the state backend. Same access grant used locally.
# Stored in repo Actions secrets so the plan workflow can read state.
variable "ci_aws_access_key_id" {
  description = "AWS_ACCESS_KEY_ID value for CI (Storj S3 access for state). Sourced from env via TF_VAR_ci_aws_access_key_id (NOT the same shell env var that the backend uses locally)."
  type        = string
  sensitive   = true
}

variable "ci_aws_secret_access_key" {
  description = "AWS_SECRET_ACCESS_KEY value for CI."
  type        = string
  sensitive   = true
}

resource "github_actions_secret" "aws_access_key_id" {
  repository  = "infrastructure"
  secret_name = "AWS_ACCESS_KEY_ID"
  value       = var.ci_aws_access_key_id
}

resource "github_actions_secret" "aws_secret_access_key" {
  repository  = "infrastructure"
  secret_name = "AWS_SECRET_ACCESS_KEY"
  value       = var.ci_aws_secret_access_key
}

# GitHub App credentials for CI to authenticate as the App.
# In CI we use actions/create-github-app-token to mint a short-lived token from
# these; we don't pass the PEM to Tofu directly in CI.
resource "github_actions_secret" "github_app_id" {
  repository  = "infrastructure"
  secret_name = "TF_GITHUB_APP_ID"
  value       = var.github_app_id
}

resource "github_actions_secret" "github_app_installation_id" {
  repository  = "infrastructure"
  secret_name = "TF_GITHUB_APP_INSTALLATION_ID"
  value       = var.github_app_installation_id
}

variable "github_app_pem_contents" {
  description = "PEM contents of the GitHub App private key, for storing as a CI secret. Sourced via TF_VAR_github_app_pem_contents (e.g., $(cat ~/.config/github-app/opentofu.pem))."
  type        = string
  sensitive   = true
}

resource "github_actions_secret" "github_app_private_key" {
  repository  = "infrastructure"
  secret_name = "TF_GITHUB_APP_PRIVATE_KEY"
  value       = var.github_app_pem_contents
}
