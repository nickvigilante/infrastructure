# Owner-scoped (not per-repo) resources for the personal namespace.
#
# Resolves the numeric GitHub user ID used as every personal repo's ruleset
# bypass_actors.actor_id (see modules/github-repo). Scaffolded now so Chunk C
# can start adding repos/personal/*.tf files without also needing this.
data "github_user" "personal_self" {
  provider = github.personal
  username = var.github_owner_personal
}
