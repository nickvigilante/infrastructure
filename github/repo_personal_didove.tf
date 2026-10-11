# nickvigilante/didove: where a command comes from (installs `dv`).

# The repo was created in the GitHub app before this context managed it, so
# the first apply adopts it instead of trying to create it.
import {
  to = module.repo_didove.github_repository.this
  id = "didove"
}

module "repo_didove" {
  source = "./modules/github-repo"

  providers = {
    github = github.personal
  }

  name            = "didove"
  bypass_actor_id = tonumber(data.github_user.personal_self.id)

  settings = merge(local.repo_defaults, {
    description = "A useful alternative to 'which'."
    topics      = ["rust", "cli", "which", "path"]

    # No CI workflow exists yet. Once one lands, require its summary job
    # here, as repo_personal_sember.tf does with ["ci"].
    required_status_check_contexts = []
  })
}
