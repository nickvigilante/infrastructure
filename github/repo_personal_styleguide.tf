# nickvigilante/styleguide: Personal writing style guide for technical documentation.

# Moved from homelab/github.tf: the import adopts the repo already in
# homelab's state, and homelab/ forgets it via a removed block (see
# docs/plans/2026-09-27-github-config-management.md, Chunk C).
import {
  to = module.repo_styleguide.github_repository.this
  id = "styleguide"
}

# The all-branches signed-commits ruleset was created by hand on 2026-11-17,
# before the module managed one, so adopt it rather than create a duplicate.
import {
  to = module.repo_styleguide.github_repository_ruleset.signed_commits[0]
  id = "styleguide:27495393"
}

module "repo_styleguide" {
  source = "./modules/github-repo"

  providers = {
    github = github.personal
  }

  name            = "styleguide"
  bypass_actor_id = tonumber(data.github_user.personal_self.id)

  settings = merge(local.repo_defaults, {
    description = "Personal writing style guide for technical documentation"
    topics      = ["style-guide", "technical-writing", "documentation"]
  })
}
