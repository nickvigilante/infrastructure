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

    # The final job of didove's .github/workflows/ci.yml, named "ci". It
    # needs the whole test matrix (ubuntu and macos: fmt, clippy, tests and
    # the MSRV check), so requiring it alone gates the lot.
    required_status_check_contexts = ["ci"]
  })
}
