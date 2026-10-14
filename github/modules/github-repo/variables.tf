variable "name" {
  description = "Repository name."
  type        = string
}

variable "settings" {
  description = "Resolved repo settings: local.repo_defaults merged with this repo's overrides."
  type = object({
    description = string
    topics      = list(string)

    visibility                  = string
    has_issues                  = bool
    has_projects                = bool
    has_wiki                    = bool
    has_discussions             = bool
    allow_squash_merge          = bool
    allow_merge_commit          = bool
    allow_rebase_merge          = bool
    allow_auto_merge            = bool
    delete_branch_on_merge      = bool
    vulnerability_alerts        = bool
    dependabot_security_updates = bool
    web_commit_signoff_required = bool
    is_template                 = bool
    auto_init                   = bool

    protect_main                    = bool
    require_conversation_resolution = bool
    required_approving_review_count = number
    dismiss_stale_reviews           = bool
    require_signed_commits          = bool
    require_code_owner_reviews      = bool
    require_linear_history          = bool
    required_status_checks_strict   = bool
    required_status_check_contexts  = list(string)
  })

  validation {
    condition     = !var.settings.dependabot_security_updates || var.settings.vulnerability_alerts
    error_message = "dependabot_security_updates requires vulnerability_alerts = true; GitHub rejects security updates while alerts are off."
  }
}

variable "bypass_actor_id" {
  description = "Numeric GitHub user ID allowed to bypass this repo's ruleset in an emergency (bypass_mode = \"always\"). Replaces classic branch_protection's blanket enforce_admins = false with an explicit, audited actor."
  type        = number
}

variable "template" {
  description = "Template repository to create this repo from, or null. Only used when the repo is created; adopted (imported) repos leave it null."
  type = object({
    owner      = string
    repository = string
  })
  default = null
}
