# nickvigilante/passgen: A lightweight, cryptographically secure password generator written in Rust.

# Moved from homelab/github.tf: the import adopts the repo already in
# homelab's state, and homelab/ forgets it via a removed block (see
# docs/plans/2026-09-27-github-config-management.md, Chunk C).
import {
  to = module.repo_passgen.github_repository.this
  id = "passgen"
}

module "repo_passgen" {
  source = "./modules/github-repo"

  providers = {
    github = github.personal
  }

  name            = "passgen"
  bypass_actor_id = tonumber(data.github_user.personal_self.id)

  settings = merge(local.repo_defaults, {
    description = "A lightweight, cryptographically secure password generator written in Rust."
    topics      = ["rust", "cli", "password-generator", "security"]
  })
}
