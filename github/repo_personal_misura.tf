# nickvigilante/misura: where an HTTP request spends its time.

# The repo was created in the GitHub app before this context managed it, so
# the first apply adopts it instead of trying to create it.
import {
  to = module.repo_misura.github_repository.this
  id = "misura"
}

# The all-branches signed-commits ruleset was created by hand on 2026-11-17,
# before the module managed one, so adopt it rather than create a duplicate.
import {
  to = module.repo_misura.github_repository_ruleset.signed_commits[0]
  id = "misura:27495385"
}

module "repo_misura" {
  source = "./modules/github-repo"

  providers = {
    github = github.personal
  }

  name            = "misura"
  bypass_actor_id = tonumber(data.github_user.personal_self.id)

  settings = merge(local.repo_defaults, {
    description = "httpstat-style request timing tool written in Rust"
    topics      = ["rust", "cli", "http", "latency", "curl"]

    # No CI workflow exists yet. Once one lands, require its summary job
    # here, as repo_personal_didove.tf does with ["ci"].
    required_status_check_contexts = []
  })
}
