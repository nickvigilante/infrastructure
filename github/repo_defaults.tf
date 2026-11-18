locals {
  # Default settings applied to every managed repo, personal or klavyn. Each
  # repo file under repos/personal/ or repos/klavyn/ instantiates
  # modules/github-repo and merges this with its own overrides -- only
  # override what differs. See docs/plans/2026-09-27-github-config-management.md
  # for the design behind this file.
  repo_defaults = {
    visibility                  = "public"
    has_issues                  = true
    has_projects                = false
    has_wiki                    = false
    has_discussions             = false
    allow_squash_merge          = true
    allow_merge_commit          = false
    allow_rebase_merge          = true
    allow_auto_merge            = true
    delete_branch_on_merge      = true
    vulnerability_alerts        = true
    dependabot_security_updates = true
    web_commit_signoff_required = false
    is_template                 = false
    auto_init                   = false

    # Branch protection defaults (applied to `main` of every repo unless
    # protect_main = false), enforced via github_repository_ruleset instead
    # of classic github_branch_protection -- see the field-mapping table in
    # docs/plans/2026-09-27-github-config-management.md (Chunk D) for why and
    # how each of these maps onto the ruleset's `rules` block.
    protect_main                    = true
    require_conversation_resolution = true
    required_approving_review_count = 0 # solo, no co-reviewers to block on
    dismiss_stale_reviews           = false
    # Signed commits everywhere: besides required_signatures on the main
    # ruleset, the module adds a separate all-branches ruleset, so an
    # unsigned push is refused on the spot rather than at merge time.
    require_signed_commits     = true
    require_code_owner_reviews = false
    require_linear_history     = false
    # Not strict: with squash merges GitHub's "update with merge commit"
    # never reaches main, and "update with rebase" is unavailable anyway
    # because GitHub cannot sign the rewritten commits.
    required_status_checks_strict  = false
    required_status_check_contexts = [] # repo-specific overrides
  }
}
