# infrastructure

Infrastructure-as-code for the things Nick runs.

Each top-level directory under this repo is a self-contained OpenTofu workspace ("context") with its own state file and provider lockfile. Contexts are independent — you `cd` into one and run `tofu` from there.

## Contexts

| Path                            | What it manages                                                                   | State key                                        |
| ------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------ |
| `cloudflare/nickvigilante-com/` | DNS, zone settings, WAF for `nickvigilante.com`                                   | `cloudflare/nickvigilante-com/terraform.tfstate` |
| `homelab/`                      | Tailscale tailnet DNS, GitHub repo settings + branch protection + Actions secrets | `homelab/terraform.tfstate`                      |

## Common conventions

- **Tool:** OpenTofu 1.10+ (`brew install opentofu`)
- **State:** stored in Storj S3-compatible bucket `nickvigilante-tfstate`. State keys mirror context paths.
- **Secrets:** never committed. Sourced from `~/.cf-opentofu.env` (out-of-repo, `chmod 600`). Each context's README lists the exact env vars it needs.
- **Pre-commit:** the [pre-commit](https://pre-commit.com) framework ([`.pre-commit-config.yaml`](./.pre-commit-config.yaml)) formats files (`tofu fmt`, prettier for Markdown, yamlfmt for YAML), lints (yamllint), and scans for secrets with [betterleaks](https://github.com/betterleaks/betterleaks) (the maintained gitleaks successor). The same hooks run in CI (`pre-commit run --all-files`). After cloning: `brew install pre-commit prettier yamlfmt yamllint betterleaks opentofu`, then `git config --unset core.hooksPath` and `pre-commit install`.
- **Branching:** all changes via feature branches + PRs to `main`. Never push to `main` directly.

## Quickstart

```bash
# 1. Load secrets into your shell
set -a && source ~/.cf-opentofu.env && set +a

# 2. Move into the context you want to work on
cd cloudflare/nickvigilante-com

# 3. First-time setup
tofu init

# 4. Day-to-day
tofu plan
tofu apply
```
