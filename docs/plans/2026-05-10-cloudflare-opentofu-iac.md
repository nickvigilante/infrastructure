# Cloudflare Zone IaC with OpenTofu — Implementation Plan

**Status:** in progress (executing 2026-05-10).

**Goal:** Manage the `nickvigilante.com` Cloudflare zone (DNS, security, WAF, zone settings) via OpenTofu with state stored in Storj, and use that managed configuration to add a WAF Skip rule that fixes the `curl` 403 on `https://nickvigilante.com/dotfiles`.

**Architecture:** This `infrastructure` repo holds one OpenTofu workspace per "context" (currently just `cloudflare/nickvigilante-com/`; `homelab/` planned). Each context has its own backend state object in a single Storj S3-compatible bucket (`nickvigilante-tfstate`), keyed by context path. The Cloudflare provider v5 manages all zone resources. Existing zone state is bootstrapped using `cf-terraforming` (Cloudflare's first-party tool that generates HCL + import blocks from a live zone), then a single Skip rule is appended to the existing WAF Custom ruleset to bypass Bot Fight Mode for `/dotfiles`.

**Tech Stack:** OpenTofu 1.10+, Cloudflare Terraform provider v5+, `cf-terraforming` v0.25+ (project uses 0.x versioning; 0.25 is what targets the v5 provider), Storj S3 Gateway-MT (`gateway.storjshare.io`), gitleaks pre-commit hook.

**Repo decision:** This work lives in `nickvigilante/infrastructure` (separate from `nickvigilante/website`) so a future `homelab/` context can share the same Terraform/state/secret-management conventions. See repo `README.md` for the multi-context overview.

---

## Tasks

### Task 1: Out-of-band prerequisites — DONE

- OpenTofu 1.11.6, awscli 2.34.45, cf-terraforming 0.25.0, gitleaks 8.30.1 — all installed via Homebrew.
- Cloudflare API token created with Zone:Read/Edit, DNS:Edit, Zone Settings:Edit, Page Rules:Edit, Cache Rules:Edit, Custom Pages:Edit, Bot Management:Edit (where available), Account:Read.
- Account ID `32467e77497570576f652f8946e632d2`, Zone ID `a38ad04ebe654b167f92db8b734ba898` captured.
- Storj bucket `nickvigilante-tfstate` created with S3-compatible read/write/list/delete credentials scoped to that bucket only.
- Storj credentials sanity-checked with `aws s3 ls` — empty bucket, exit 0.
- Secrets exported via `~/.cf-opentofu.env` (chmod 600), sourced into shell before each `tofu`/`aws` invocation.

### Task 2: Bootstrap infrastructure repo — DONE

- Created `nickvigilante/infrastructure` (public) on GitHub.
- Initial commit on `main`: top-level `README.md` (multi-context overview + quickstart), `.gitignore` (OS, editor, OpenTofu, secrets).
- Switched to `feat/cloudflare-zone-iac` for all subsequent work — single PR for the whole IaC initial setup.

### Task 3: gitleaks pre-commit hook — DONE

- `.gitleaks.toml` extends the built-in default ruleset.
- `.githooks/pre-commit` runs `gitleaks git --staged` on every commit; fails commit on detection.
- Activated per-clone with `git config core.hooksPath .githooks`.
- Verified by attempting to commit a file with fake (non-allowlisted) GitHub PAT, Stripe key, and AWS key patterns — commit blocked with 3 leaks reported. AWS docs canonical example (`AKIA...EXAMPLE`) was correctly allowlisted by default, which is why it took two test attempts.

### Task 4: Scaffold cloudflare/nickvigilante-com/ — IN PROGRESS

**Files:**

- `cloudflare/nickvigilante-com/versions.tf` — required_version 1.10+, cloudflare/cloudflare ~> 5.0
- `cloudflare/nickvigilante-com/provider.tf` — provider auth via `var.cloudflare_api_token`
- `cloudflare/nickvigilante-com/backend.tf` — Storj S3 backend, key `cloudflare/nickvigilante-com/terraform.tfstate`, `use_lockfile = true`
- `cloudflare/nickvigilante-com/variables.tf` — api_token (env var), account_id + zone_id (hardcoded defaults; not secret)
- `docs/plans/2026-05-10-cloudflare-opentofu-iac.md` (this file)

### Task 5: Initialize Storj backend

```bash
cd cloudflare/nickvigilante-com
set -a && source ~/.cf-opentofu.env && set +a
tofu init
```

Expected: "Successfully configured the backend s3", "Installing cloudflare/cloudflare v5.x.x", "OpenTofu has been successfully initialized!".

If `use_lockfile = true` errors with "conditional writes not supported", set `use_lockfile = false` in `backend.tf` (Storj's S3 gateway may not implement S3 conditional writes). Solo-user, no real lock contention risk.

Verify state object exists:

```bash
aws s3 ls s3://nickvigilante-tfstate/cloudflare/nickvigilante-com/ --endpoint-url https://gateway.storjshare.io
```

Commit `.terraform.lock.hcl`.

### Task 6: Verify provider auth with a data source

Add `cloudflare/nickvigilante-com/data.tf`:

```hcl
data "cloudflare_zone" "this" {
  zone_id = var.cloudflare_zone_id
}

output "zone_name" {
  value = data.cloudflare_zone.this.name
}
```

`tofu plan` then `tofu apply` — expect `zone_name = "nickvigilante.com"` output, no resource changes.

### Task 7: Generate import config with cf-terraforming

```bash
mkdir -p _generated   # gitignored via root **/_generated/ pattern
export CLOUDFLARE_API_TOKEN=$TF_VAR_cloudflare_api_token
export CLOUDFLARE_ZONE_ID=$TF_VAR_cloudflare_zone_id

cf-terraforming generate --resource-type cloudflare_dns_record   --zone $CLOUDFLARE_ZONE_ID > _generated/dns.tf
cf-terraforming generate --resource-type cloudflare_ruleset      --zone $CLOUDFLARE_ZONE_ID > _generated/rulesets.tf
cf-terraforming generate --resource-type cloudflare_zone_setting --zone $CLOUDFLARE_ZONE_ID > _generated/zone_settings.tf

cf-terraforming generate --resource-type cloudflare_dns_record   --zone $CLOUDFLARE_ZONE_ID --modern-import-block > _generated/dns_imports.tf
cf-terraforming generate --resource-type cloudflare_ruleset      --zone $CLOUDFLARE_ZONE_ID --modern-import-block > _generated/rulesets_imports.tf
cf-terraforming generate --resource-type cloudflare_zone_setting --zone $CLOUDFLARE_ZONE_ID --modern-import-block > _generated/zone_settings_imports.tf
```

(Note: I used the `--modern-import-block` global flag instead of the separate `cf-terraforming import` subcommand because v0.25 supports the declarative `import {}` form, which is cleaner.)

Inspect outputs and note any resources cf-terraforming doesn't support (call out in the per-context README so future-Nick knows what's still dashboard-only).

### Task 8: Import DNS records

Hand-curate `_generated/dns.tf` into `cloudflare/nickvigilante-com/dns.tf`:

- Rename `terraform_managed_resource_<uuid>` blocks to descriptive names (e.g., `apex_a`, `mx_proton_1`).
- Replace hardcoded zone IDs with `var.cloudflare_zone_id`.
- Append `import {}` blocks at the bottom of the file.

`tofu plan` — expect `Plan: <N> to import, 0 to add, 0 to change, 0 to destroy.`

If the plan shows `to change` instead of clean imports, the generated HCL drifted from live state — usually a default value cf-terraforming omitted. Add the missing fields until plan is clean. **Do not apply with drift; that overwrites live state with the HCL.**

`tofu apply`. Re-run `tofu plan` for idempotency check (expect "No changes"). Remove the `import {}` blocks. Commit.

### Task 9: Import zone settings

Same pattern as Task 8, file `cloudflare/nickvigilante-com/zone_settings.tf`. Resources are `cloudflare_zone_setting`. One resource per setting (e.g., `always_use_https`, `min_tls_version`, `brotli`).

### Task 10: Import or create WAF custom ruleset

Inspect `_generated/rulesets.tf`. Look for a block with `phase = "http_request_firewall_custom"`.

- **If exists:** import to `cloudflare/nickvigilante-com/waf.tf` as `cloudflare_ruleset.zone_custom_firewall`.
- **If absent:** create empty ruleset (`rules = []`) — Task 11 will populate.

### Task 11: Add Skip rule for /dotfiles

Reproduce the bug:

```bash
curl -sI https://nickvigilante.com/dotfiles | grep -iE "(HTTP|cf-mitigated)"
```

Expect `HTTP/2 403`, `cf-mitigated: challenge`.

Add to the top of `cloudflare_ruleset.zone_custom_firewall`'s `rules` list:

```hcl
{
  ref         = "skip_bots_for_dotfiles"
  description = "Allow curl to fetch /dotfiles bootstrap script (skips bot fight mode)"
  expression  = "(http.request.uri.path eq \"/dotfiles\")"
  action      = "skip"
  action_parameters = {
    products = ["bic", "uaBlock", "zoneLockdown", "rateLimit", "securityLevel", "hot", "bot_management"]
    ruleset  = "current"
  }
  enabled = true
}
```

`tofu apply`. Wait ~30s for edge propagation.

Verify:

```bash
curl -sI https://nickvigilante.com/dotfiles | head -5
```

Expect `HTTP/2 302`, `location: https://raw.githubusercontent.com/...`

End-to-end:

```bash
bash -c "$(curl -fsSL https://nickvigilante.com/dotfiles)"
```

Should run install.sh.

If still 403, expand the `products` list based on the residual `cf-mitigated:` header value.

### Task 12: Document the setup

- `cloudflare/nickvigilante-com/README.md` — env vars, usage, what's managed, what's NOT managed (cf-terraforming gaps), state location, token rotation procedure.
- Top-level `README.md` already covers multi-context conventions.
- Clean up `_generated/` scratch directory.

### Task 13: Cross-repo pointer

In `nickvigilante/website` repo, add a one-liner to `CLAUDE.md` noting that DNS/WAF/zone settings now live in `nickvigilante/infrastructure` and should not be edited in the dashboard. Separate PR in the website repo.

---

## Decisions worth noting

- **Repo separation:** Cloudflare zone config lives in `infrastructure`, not `website`, because a homelab is planned and we want a single home for all IaC contexts. Trade-off: PRs that touch both code and infra now span two repos. For Nick's solo workflow, this is fine; the two PRs can reference each other.
- **State backend = Storj over Cloudflare R2:** avoids a circular dependency where Terraform managing the Cloudflare account also stores its state inside the Cloudflare account. Storj is also already paid for.
- **Bot Fight Mode kept on:** Skip rule scoped to just `/dotfiles` rather than disabling BFM zone-wide. Other paths still benefit from the protection.
- **Public repo:** zone/account IDs and DNS records are not secret. State + tokens stay out of the repo. gitleaks pre-commit catches accidental secret commits.
