# nickvigilante/dotfiles: Configuration files for development environments.

# Moved from homelab/github.tf: the import adopts the repo already in
# homelab's state, and homelab/ forgets it via a removed block (see
# docs/plans/2026-09-27-github-config-management.md, Chunk C).
import {
  to = module.repo_dotfiles.github_repository.this
  id = "dotfiles"
}

# The `main` ruleset was created by hand before this context managed it, so
# adopt it rather than create a second one (GitHub rejects duplicate names).
import {
  to = module.repo_dotfiles.github_repository_ruleset.main[0]
  id = "dotfiles:24078683"
}

module "repo_dotfiles" {
  source = "./modules/github-repo"

  providers = {
    github = github.personal
  }

  name            = "dotfiles"
  bypass_actor_id = tonumber(data.github_user.personal_self.id)

  settings = merge(local.repo_defaults, {
    description = "Configuration files for development environments"
    topics      = ["chezmoi", "dotfiles", "zsh", "shell-config"]

    required_status_check_contexts = ["ci"]
  })
}
