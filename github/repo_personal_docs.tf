# nickvigilante/docs: Documentation repository.

# Moved from homelab/github.tf: the import adopts the repo already in
# homelab's state, and homelab/ forgets it via a removed block (see
# docs/plans/2026-09-27-github-config-management.md, Chunk C).
import {
  to = module.repo_docs.github_repository.this
  id = "docs"
}

module "repo_docs" {
  source = "./modules/github-repo"

  providers = {
    github = github.personal
  }

  name            = "docs"
  bypass_actor_id = tonumber(data.github_user.personal_self.id)

  settings = merge(local.repo_defaults, {
    description = "Documentation repository"
    topics      = ["docs", "mdx"]
  })
}
