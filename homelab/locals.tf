locals {
  # Classic branch-protection settings for the repos github/ now manages.
  # Repo settings themselves moved to github/repo_personal_*.tf; this only
  # feeds github_branch_protection.main in github.tf until the rulesets that
  # replace it are verified (docs/plans/2026-09-27-github-config-management.md,
  # Chunk D). Delete it along with that resource.
  repo_defaults = {
    protect_main                    = true
    require_conversation_resolution = true
    required_approving_review_count = 0 # solo, no co-reviewers to block on
    dismiss_stale_reviews           = false
    require_signed_commits          = false
    require_code_owner_reviews      = false
    require_linear_history          = false
    required_status_checks_strict   = true
    required_status_check_contexts  = [] # repo-specific overrides
  }

  # infrastructure, dotfiles and homelab are absent on purpose: their classic
  # protection was already replaced by hand-made rulesets, which github/ now
  # imports.
  repos = {
    puzzles             = {}
    tuile               = {}
    docs                = {}
    passgen             = {}
    styleguide          = {}
    "vale-languagetool" = {}
    tools               = {}
  }

  repos_resolved = {
    for name, cfg in local.repos : name => merge(local.repo_defaults, cfg)
  }
}
