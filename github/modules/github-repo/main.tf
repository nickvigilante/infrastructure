# One managed repo's resources. Each instantiation lives in its own file
# under repos/personal/ or repos/klavyn/ in the root module -- see
# docs/plans/2026-09-27-github-config-management.md for why.
#
# IMPORTANT: lifecycle.prevent_destroy on the repo. `tofu destroy` will
# refuse to delete a managed repository. To actually delete a repo you must
# first remove the prevent_destroy attribute, apply, then destroy. Mirrors
# homelab/github.tf's existing convention.
resource "github_repository" "this" {
  name        = var.name
  description = var.settings.description
  topics      = var.settings.topics

  visibility                  = var.settings.visibility
  has_issues                  = var.settings.has_issues
  has_projects                = var.settings.has_projects
  has_wiki                    = var.settings.has_wiki
  has_discussions             = var.settings.has_discussions
  allow_squash_merge          = var.settings.allow_squash_merge
  allow_merge_commit          = var.settings.allow_merge_commit
  allow_rebase_merge          = var.settings.allow_rebase_merge
  allow_auto_merge            = var.settings.allow_auto_merge
  delete_branch_on_merge      = var.settings.delete_branch_on_merge
  web_commit_signoff_required = var.settings.web_commit_signoff_required

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_vulnerability_alerts" "this" {
  count      = var.settings.vulnerability_alerts ? 1 : 0
  repository = github_repository.this.name
}

resource "github_repository_dependabot_security_updates" "this" {
  count      = var.settings.dependabot_security_updates ? 1 : 0
  repository = github_repository.this.name
  enabled    = true
}

locals {
  # allowed_merge_methods is required by the ruleset's pull_request rule
  # (min 1 entry) -- derived from the same three repo-level merge-method
  # booleans rather than duplicated as a separate setting, so the two can't
  # drift apart.
  allowed_merge_methods = compact([
    var.settings.allow_merge_commit ? "merge" : null,
    var.settings.allow_squash_merge ? "squash" : null,
    var.settings.allow_rebase_merge ? "rebase" : null,
  ])
}

# Branch protection on the default branch, via a repository ruleset instead
# of classic github_branch_protection -- see the field-mapping table in
# docs/plans/2026-09-27-github-config-management.md (Chunk D) for the
# reasoning and the classic -> ruleset field mapping this mirrors.
resource "github_repository_ruleset" "main" {
  count = var.settings.protect_main ? 1 : 0

  name        = "main"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  # Explicit, audited bypass actor -- replaces classic branch_protection's
  # blanket enforce_admins = false (which lets any admin silently skip
  # protection with no record of it happening).
  bypass_actors {
    actor_id    = var.bypass_actor_id
    actor_type  = "User"
    bypass_mode = "always"
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = var.settings.require_linear_history
    required_signatures     = var.settings.require_signed_commits

    pull_request {
      required_approving_review_count   = var.settings.required_approving_review_count
      dismiss_stale_reviews_on_push     = var.settings.dismiss_stale_reviews
      require_code_owner_review         = var.settings.require_code_owner_reviews
      required_review_thread_resolution = var.settings.require_conversation_resolution
      allowed_merge_methods             = local.allowed_merge_methods
    }

    # Only emit required_status_checks if there are checks to require -- an
    # empty block would still turn on "strict" with nothing to satisfy,
    # blocking merges forever. Mirrors homelab/github.tf's existing
    # reasoning for the same dynamic block.
    dynamic "required_status_checks" {
      for_each = length(var.settings.required_status_check_contexts) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = var.settings.required_status_checks_strict

        dynamic "required_check" {
          for_each = var.settings.required_status_check_contexts
          content {
            context = required_check.value
          }
        }
      }
    }
  }
}
