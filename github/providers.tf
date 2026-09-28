provider "github" {
  alias = "personal"
  owner = var.github_owner_personal

  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id_personal
    pem_file        = file(var.github_app_pem_file)
  }
}

# Klavyn org installation. Not yet usable for real API calls --
# github_app_installation_id_klavyn has no real value until the GitHub App is
# installed on the klavyn org (see docs/plans/2026-09-27-github-config-management.md,
# Chunk E). Scaffolded now so Chunk E only needs to add repo files under
# repos/klavyn/, not this provider block.
provider "github" {
  alias = "klavyn"
  owner = var.github_owner_klavyn

  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id_klavyn
    pem_file        = file(var.github_app_pem_file)
  }
}
