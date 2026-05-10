# infrastructure

Infrastructure-as-code for the things Nick runs.

Each top-level directory under this repo is a self-contained OpenTofu workspace ("context") with its own state file and provider lockfile. Contexts are independent — you `cd` into one and run `tofu` from there.

## Contexts

| Path | What it manages | State key |
|------|-----------------|-----------|
| `cloudflare/nickvigilante-com/` | DNS, zone settings, WAF for `nickvigilante.com` | `cloudflare/nickvigilante-com/terraform.tfstate` |

Future contexts (planned, not yet wired up): `homelab/`.

## Common conventions

- **Tool:** OpenTofu 1.10+ (`brew install opentofu`)
- **State:** stored in Storj S3-compatible bucket `nickvigilante-tfstate`. State keys mirror context paths.
- **Secrets:** never committed. Sourced from `~/.cf-opentofu.env` (out-of-repo, `chmod 600`). Each context's README lists the exact env vars it needs.
- **Pre-commit:** `gitleaks` runs on every commit to catch accidentally-staged secrets. See [`.gitleaks.toml`](./.gitleaks.toml).
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
