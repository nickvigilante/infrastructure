# nickvigilante/puzzles: A fork of Simon Tatham's Puzzles for macOS.

# Moved from homelab/github.tf: the import adopts the repo already in
# homelab's state, and homelab/ forgets it via a removed block (see
# docs/plans/2026-09-27-github-config-management.md, Chunk C).
import {
  to = module.repo_puzzles.github_repository.this
  id = "puzzles"
}

module "repo_puzzles" {
  source = "./modules/github-repo"

  providers = {
    github = github.personal
  }

  name            = "puzzles"
  bypass_actor_id = tonumber(data.github_user.personal_self.id)

  settings = merge(local.repo_defaults, {
    description = "A fork of Simon Tatham's Puzzles for macOS"
    topics      = ["puzzles", "macos", "games"]
  })
}
