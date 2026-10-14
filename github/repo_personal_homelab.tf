# nickvigilante/homelab: k3s manifests, Helm values, and host system configs for my home lab on gandalf.

# Moved from homelab/github.tf: the import adopts the repo already in
# homelab's state, and homelab/ forgets it via a removed block (see
# docs/plans/2026-09-27-github-config-management.md, Chunk C).
import {
  to = module.repo_homelab.github_repository.this
  id = "homelab"
}

module "repo_homelab" {
  source = "./modules/github-repo"

  providers = {
    github = github.personal
  }

  name            = "homelab"
  bypass_actor_id = tonumber(data.github_user.personal_self.id)

  settings = merge(local.repo_defaults, {
    description = "k3s manifests, Helm values, and host system configs for my home lab on gandalf"
    topics      = ["homelab", "kubernetes", "k3s", "helm", "jellyfin", "pi-hole"]
  })
}
