locals {
  # Default settings applied to every managed repo. Per-repo overrides go in
  # local.repos below.
  repo_defaults = {
    visibility                  = "public"
    has_issues                  = true
    has_projects                = false
    has_wiki                    = false
    has_discussions             = false
    has_downloads               = false
    allow_squash_merge          = true
    allow_merge_commit          = false
    allow_rebase_merge          = true
    allow_auto_merge            = false
    delete_branch_on_merge      = true
    vulnerability_alerts        = true
    web_commit_signoff_required = false

    # Branch protection defaults (applied to `main` of every repo unless
    # protect_main = false).
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

  # Per-repo definitions. Each entry merges with repo_defaults — only override
  # what differs. Adding a repo to this map causes Tofu to import or create it.
  repos = {
    infrastructure = {
      description = "Infrastructure as code for nickvigilante.com Cloudflare zone, future homelab, and other infra. Managed with OpenTofu."
      topics      = ["opentofu", "terraform", "infrastructure-as-code", "homelab", "cloudflare"]
      # Require the homelab-plan workflow to pass before merging anything that
      # touches homelab/. Workflow name "homelab-plan" matches the job in
      # .github/workflows/homelab-plan.yml.
      required_status_check_contexts = ["homelab-plan"]
    }
    dotfiles = {
      description = "Configuration files for development environment"
      topics      = ["dotfiles", "zsh", "shell-config"]
    }
    puzzles = {
      description = "A fork of Simon Tatham's Puzzles for macOS"
      topics      = ["puzzles", "macos", "games"]
    }
    tuile = {
      description = "A widget and layout library for ratatui"
      topics      = ["ratatui", "rust", "tui"]
    }
    docs = {
      description = "Documentation repository"
      topics      = ["docs", "mdx"]
    }
    passgen = {
      description = "A lightweight, cryptographically secure password generator written in Rust."
      topics      = ["rust", "cli", "password-generator", "security"]
    }
    styleguide = {
      description = "Personal writing style guide for technical documentation"
      topics      = ["style-guide", "technical-writing", "documentation"]
    }
    "vale-languagetool" = {
      description = "An implementation of all LanguageTool rules in Vale"
      topics      = ["vale", "languagetool", "linter"]
    }
    tools = {
      description = "A lightweight password generator written in Python."
      topics      = ["python", "cli", "tools"]
    }
  }

  # Merge defaults with per-repo overrides for use by resources below.
  repos_resolved = {
    for name, cfg in local.repos : name => merge(local.repo_defaults, cfg)
  }
}
