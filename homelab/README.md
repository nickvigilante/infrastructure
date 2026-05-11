# homelab

OpenTofu context for home-lab infrastructure that lives outside the k3s cluster:

- **Tailscale** — tailnet Global Nameserver (gandalf at `100.92.2.25`), MagicDNS toggle.
- **GitHub** — repository settings + branch protection for every public repo under `nickvigilante/`, plus the Actions secrets the CI plan workflow needs.

Everything inside the k3s cluster (Helm releases, PVs, Secrets) is managed by Helm + raw YAML under `~/homelab/k8s/` on gandalf — **not** by Tofu.

## Env vars required at apply time

Source `~/.homelab-opentofu.env` (chmod 600, out-of-repo):

```bash
set -a && source ~/.homelab-opentofu.env && set +a
```

The file should export:

```bash
# Tailscale OAuth client (scope: dns) for the opentofu-homelab integration
export TF_VAR_tailscale_oauth_client_id="tskey-client-..."
export TF_VAR_tailscale_oauth_client_secret="tskey-secret-..."

# GitHub App: ID + Installation ID + path to private-key PEM
export TF_VAR_github_app_id="<App ID>"
export TF_VAR_github_app_installation_id="<Installation ID>"
export TF_VAR_github_app_pem_file="$HOME/.config/github-app/opentofu.pem"

# For storing the same App credentials as Actions secrets on the infra repo,
# Tofu also needs the PEM contents directly:
export TF_VAR_github_app_pem_contents="$(cat $HOME/.config/github-app/opentofu.pem)"

# Storj S3 credentials for state backend (same access grant as .cf-opentofu.env)
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."

# Same Storj credentials, but for CI Actions secrets (they get pushed as repo secrets)
export TF_VAR_ci_aws_access_key_id="$AWS_ACCESS_KEY_ID"
export TF_VAR_ci_aws_secret_access_key="$AWS_SECRET_ACCESS_KEY"
```

## Quickstart

```bash
# Source the env file
set -a && source ~/.homelab-opentofu.env && set +a

# Move into this context
cd homelab/

# First time
tofu init

# Preview changes
tofu plan

# Apply
tofu apply
```

## What's in here

| File | Purpose |
|------|---------|
| `versions.tf` | Required provider versions + minimum tofu version |
| `backend.tf` | Storj S3 backend (`s3://nickvigilante-tfstate/homelab/terraform.tfstate`) |
| `providers.tf` | tailscale + github provider configs |
| `variables.tf` | Input variables (all sourced from env via `TF_VAR_*`) |
| `locals.tf` | Per-repo configuration map; add new repos here |
| `tailscale.tf` | Tailnet DNS settings |
| `github.tf` | Repo settings, branch protection, Actions secrets |
| `outputs.tf` | Useful outputs (managed repo list, protected repo list) |

## Importing existing resources on first apply

GitHub repos already exist; this context **creates them on first apply if missing, or you import them**. Easier path is to import them so Tofu picks up current state:

```bash
# Run once after `tofu init`, before `tofu apply`:
for repo in infrastructure dotfiles puzzles tuile docs passgen styleguide vale-languagetool tools; do
  tofu import "github_repository.managed[\"$repo\"]" "$repo"
done
```

Tailnet DNS settings are singleton — Tofu manages a single resource that overwrites whatever's in the admin UI. No import needed; the first `tofu apply` will replace the current Global Nameserver setting with whatever's in `tailscale.tf` (currently the same `100.92.2.25` you already set manually).

## Adding a new repo

1. Add an entry to `local.repos` in `locals.tf`.
2. `tofu plan` — confirms the create or import is what you expect.
3. `tofu import` (for existing) or `tofu apply` (for create new).
