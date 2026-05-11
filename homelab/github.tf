# Managed repos. Each one is either created (if missing) or imported on first
# apply. Settings derive from local.repos_resolved.
#
# IMPORTANT: lifecycle.prevent_destroy on every repo. `tofu destroy` will refuse
# to delete a managed repository. To actually delete a repo you must first
# remove the prevent_destroy attribute, apply, then destroy.
resource "github_repository" "managed" {
  for_each = local.repos_resolved

  name        = each.key
  description = each.value.description
  topics      = each.value.topics

  visibility                  = each.value.visibility
  has_issues                  = each.value.has_issues
  has_projects                = each.value.has_projects
  has_wiki                    = each.value.has_wiki
  has_discussions             = each.value.has_discussions
  has_downloads               = each.value.has_downloads
  allow_squash_merge          = each.value.allow_squash_merge
  allow_merge_commit          = each.value.allow_merge_commit
  allow_rebase_merge          = each.value.allow_rebase_merge
  allow_auto_merge            = each.value.allow_auto_merge
  delete_branch_on_merge      = each.value.delete_branch_on_merge
  vulnerability_alerts        = each.value.vulnerability_alerts
  web_commit_signoff_required = each.value.web_commit_signoff_required

  lifecycle {
    prevent_destroy = true
  }
}

# Branch protection on `main` for every repo where protect_main = true.
resource "github_branch_protection" "main" {
  for_each = {
    for name, cfg in local.repos_resolved : name => cfg
    if cfg.protect_main
  }

  repository_id                   = github_repository.managed[each.key].node_id
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
resource "github_actions_secret" "tailscale_oauth_client_id" {
  repository      = github_repository.managed["infrastructure"].name
  secret_name     = "TAILSCALE_OAUTH_CLIENT_ID"
  plaintext_value = var.tailscale_oauth_client_id
}

resource "github_actions_secret" "tailscale_oauth_client_secret" {
  repository      = github_repository.managed["infrastructure"].name
  secret_name     = "TAILSCALE_OAUTH_CLIENT_SECRET"
  plaintext_value = var.tailscale_oauth_client_secret
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
  repository      = github_repository.managed["infrastructure"].name
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = var.ci_aws_access_key_id
}

resource "github_actions_secret" "aws_secret_access_key" {
  repository      = github_repository.managed["infrastructure"].name
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = var.ci_aws_secret_access_key
}

# GitHub App credentials for CI to authenticate as the App.
# In CI we use actions/create-github-app-token to mint a short-lived token from
# these; we don't pass the PEM to Tofu directly in CI.
resource "github_actions_secret" "github_app_id" {
  repository      = github_repository.managed["infrastructure"].name
  secret_name     = "TF_GITHUB_APP_ID"
  plaintext_value = var.github_app_id
}

resource "github_actions_secret" "github_app_installation_id" {
  repository      = github_repository.managed["infrastructure"].name
  secret_name     = "TF_GITHUB_APP_INSTALLATION_ID"
  plaintext_value = var.github_app_installation_id
}

variable "github_app_pem_contents" {
  description = "PEM contents of the GitHub App private key, for storing as a CI secret. Sourced via TF_VAR_github_app_pem_contents (e.g., $(cat ~/.config/github-app/opentofu.pem))."
  type        = string
  sensitive   = true
}

resource "github_actions_secret" "github_app_private_key" {
  repository      = github_repository.managed["infrastructure"].name
  secret_name     = "TF_GITHUB_APP_PRIVATE_KEY"
  plaintext_value = var.github_app_pem_contents
}
