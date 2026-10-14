# nickvigilante/infrastructure: this repo.

# Moved from homelab/github.tf: the import adopts the repo already in
# homelab's state, and homelab/ forgets it via a removed block (see
# docs/plans/2026-09-27-github-config-management.md, Chunk C).
import {
  to = module.repo_infrastructure.github_repository.this
  id = "infrastructure"
}

# The `main` ruleset was created by hand before this context managed it, so
# adopt it rather than create a second one (GitHub rejects duplicate names).
import {
  to = module.repo_infrastructure.github_repository_ruleset.main[0]
  id = "infrastructure:23691967"
}

module "repo_infrastructure" {
  source = "./modules/github-repo"

  providers = {
    github = github.personal
  }

  name            = "infrastructure"
  bypass_actor_id = tonumber(data.github_user.personal_self.id)

  settings = merge(local.repo_defaults, {
    description = "Infrastructure as code for nickvigilante.com Cloudflare zone, future homelab, and other infra. Managed with OpenTofu."
    topics      = ["opentofu", "terraform", "infrastructure-as-code", "homelab", "cloudflare"]

    # Both plan workflows always run and report (their tofu steps are gated
    # on path detection instead), so requiring them never blocks a PR that
    # doesn't touch their context.
    required_status_check_contexts = [
      "homelab-plan",
      "github-plan",
      "pre-commit (format + lint + secrets)",
    ]
    required_status_checks_strict = false
    require_linear_history        = true
  })
}

# ---------------------------------------------------------------------------
# Approval gates for the homelab-apply and github-apply workflows.
#
# Each workflow runs `tofu apply` against its context, so an unattended
# dispatch could overwrite live config before you notice. The environment
# forces a manual approval click in the Actions UI before apply runs.
#
# Deployments are pinned to `main` with an explicit branch policy rather than
# `protected_branches = true`: that option only counts classic branch
# protection rules, and once `main` is protected solely by a ruleset GitHub
# treats the repo as having no protected branches -- letting every branch
# deploy.
# ---------------------------------------------------------------------------
import {
  to = github_repository_environment.homelab_apply
  id = "infrastructure:homelab-apply"
}

resource "github_repository_environment" "homelab_apply" {
  provider    = github.personal
  repository  = module.repo_infrastructure.repo_name
  environment = "homelab-apply"

  reviewers {
    users = [tonumber(data.github_user.personal_self.id)]
  }

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "homelab_apply_main" {
  provider       = github.personal
  repository     = module.repo_infrastructure.repo_name
  environment    = github_repository_environment.homelab_apply.environment
  branch_pattern = "main"
}

resource "github_repository_environment" "github_apply" {
  provider    = github.personal
  repository  = module.repo_infrastructure.repo_name
  environment = "github-apply"

  reviewers {
    users = [tonumber(data.github_user.personal_self.id)]
  }

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "github_apply_main" {
  provider       = github.personal
  repository     = module.repo_infrastructure.repo_name
  environment    = github_repository_environment.github_apply.environment
  branch_pattern = "main"
}
