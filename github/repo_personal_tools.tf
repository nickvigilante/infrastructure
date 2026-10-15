# nickvigilante/tools: A lightweight password generator written in Python.

# Moved from homelab/github.tf: the import adopts the repo already in
# homelab's state, and homelab/ forgets it via a removed block (see
# docs/plans/2026-09-27-github-config-management.md, Chunk C).
import {
  to = module.repo_tools.github_repository.this
  id = "tools"
}

module "repo_tools" {
  source = "./modules/github-repo"

  providers = {
    github = github.personal
  }

  name            = "tools"
  bypass_actor_id = tonumber(data.github_user.personal_self.id)

  settings = merge(local.repo_defaults, {
    description = "A lightweight password generator written in Python."
    topics      = ["python", "cli", "tools"]
  })
}
