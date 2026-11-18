# nickvigilante/tuile: A widget and layout library for ratatui.

# Moved from homelab/github.tf: the import adopts the repo already in
# homelab's state, and homelab/ forgets it via a removed block (see
# docs/plans/2026-09-27-github-config-management.md, Chunk C).
import {
  to = module.repo_tuile.github_repository.this
  id = "tuile"
}

# The all-branches signed-commits ruleset was created by hand on 2026-11-17,
# before the module managed one, so adopt it rather than create a duplicate.
import {
  to = module.repo_tuile.github_repository_ruleset.signed_commits[0]
  id = "tuile:27495398"
}

module "repo_tuile" {
  source = "./modules/github-repo"

  providers = {
    github = github.personal
  }

  name            = "tuile"
  bypass_actor_id = tonumber(data.github_user.personal_self.id)

  settings = merge(local.repo_defaults, {
    description = "A widget and layout library for ratatui"
    topics      = ["ratatui", "rust", "tui"]
  })
}
