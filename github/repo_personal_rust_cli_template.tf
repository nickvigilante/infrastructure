# nickvigilante/rust-cli-template: the starting point for new Rust CLIs.
#
# Created here rather than in the GitHub app. auto_init gives it a first
# commit so main exists for the PR that adds the template's files. New tool
# repos are then created from it by passing this module's `template`
# variable:
#
#   template = {
#     owner      = "nickvigilante"
#     repository = module.repo_rust_cli_template.repo_name
#   }

module "repo_rust_cli_template" {
  source = "./modules/github-repo"

  providers = {
    github = github.personal
  }

  name            = "rust-cli-template"
  bypass_actor_id = tonumber(data.github_user.personal_self.id)

  settings = merge(local.repo_defaults, {
    description = "Starting point for my Rust command-line tools: MIT OR Apache-2.0, CI on Linux and macOS, and a fast release profile."
    topics      = ["rust", "cli", "template"]
    is_template = true
    auto_init   = true

    # The template's own CI doesn't exist until its first PR lands; require
    # its "ci" job here once it does.
    required_status_check_contexts = []
  })
}
