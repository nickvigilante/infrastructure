# nickvigilante/passgen: A lightweight, cryptographically secure password generator written in Rust.

# Moved from homelab/github.tf: the import adopts the repo already in
# homelab's state, and homelab/ forgets it via a removed block (see
# docs/plans/2026-09-27-github-config-management.md, Chunk C).
import {
  to = module.repo_passgen.github_repository.this
  id = "passgen"
}

# The `main` ruleset was created by hand before this context managed it, so
# adopt it rather than create a second one (GitHub rejects duplicate names).
import {
  to = module.repo_passgen.github_repository_ruleset.main[0]
  id = "passgen:6250510"
}

# The all-branches signed-commits ruleset was created by hand on 2026-11-17,
# before the module managed one, so adopt it rather than create a duplicate.
import {
  to = module.repo_passgen.github_repository_ruleset.signed_commits[0]
  id = "passgen:27495387"
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

    # Kept from the hand-made ruleset this adopts.
    require_linear_history = true
  })
}
