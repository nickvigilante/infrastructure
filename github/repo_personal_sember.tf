# nickvigilante/sember: semantic line break formatter.
#
# Lives at the root of github/ rather than under repos/personal/ as the plan
# sketches, because OpenTofu only loads .tf files from the root module's own
# directory; files in a subdirectory are ignored unless that directory is
# itself called as a module.

# The repo was created in the GitHub app before this context managed it, so
# the first apply adopts it instead of trying to create it.
import {
  to = module.repo_sember.github_repository.this
  id = "sember"
}

module "repo_sember" {
  source = "./modules/github-repo"

  providers = {
    github = github.personal
  }

  name            = "sember"
  bypass_actor_id = tonumber(data.github_user.personal_self.id)

  settings = merge(local.repo_defaults, {
    description = "Semantic line breaks for cleaner text and smaller, more manageable diffs."
    topics      = ["rust", "cli", "markdown", "formatter", "semantic-line-breaks"]

    # The single job in sember's .github/workflows/ci.yml: fmt, clippy,
    # tests, the MSRV build and sember --check on its own README.
    required_status_check_contexts = ["ci"]
  })
}
