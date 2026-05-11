# cloudflare/nickvigilante-com

OpenTofu workspace managing the Cloudflare zone for `nickvigilante.com`.

## Prerequisites

- OpenTofu 1.10+ (`brew install opentofu`)
- Cloudflare API token scoped to this zone with: Zone:Read, Zone Settings:Edit, DNS:Edit, Zone WAF:Edit, Bot Management:Edit
- Storj S3-compatible credentials with read/write/list/delete on the `nickvigilante-tfstate` bucket

## Environment

Stored out-of-repo at `~/.cf-opentofu.env` (`chmod 600`):

```bash
export TF_VAR_cloudflare_api_token="<cf-token>"
export AWS_ACCESS_KEY_ID="<storj-access-key>"
export AWS_SECRET_ACCESS_KEY="<storj-secret-key>"
```

Source before any `tofu` command:

```bash
set -a && source ~/.cf-opentofu.env && set +a
```

Account ID and zone ID are baked into [`variables.tf`](./variables.tf) defaults — they're identifiers, not secrets.

## Usage

```bash
cd cloudflare/nickvigilante-com
set -a && source ~/.cf-opentofu.env && set +a

tofu init     # first time only
tofu plan     # dry-run; commit results in PRs
tofu apply    # apply changes
```

## What's managed

| File | Resources |
|------|-----------|
| [`dns.tf`](./dns.tf) | All 7 DNS records (A, CNAME, NS×2, TXT×3 for SPF/DMARC/DKIM) |
| [`waf.tf`](./waf.tf) | The `http_request_firewall_custom` ruleset and its rules |
| [`bot_management.tf`](./bot_management.tf) | Bot Fight Mode, AI bots protection, crawler protection, JS challenge enable |
| [`data.tf`](./data.tf) | Read-only zone lookup (sanity check) |

## What's NOT managed (still dashboard-only)

These need follow-up PRs to bring under OpenTofu:

- **Zone settings** (security_level, browser_check, min_tls_version, brotli, etc.) — `cf-terraforming` for `cloudflare_zone_setting` requires explicit enumeration of every setting name; deferred to a focused follow-up rather than blocking the IaC bootstrap.
- **Account-level firewall rules** — none currently configured, but if added later they should be managed here too.
- **Workers, Workers routes, R2 / KV / D1 bindings** — managed via `wrangler.jsonc` in the `nickvigilante/website` repo.
- **Page Rules** — none currently configured.
- **Account-level Cloudflare One / Access policies** — none in use.

## What's vestigial (importing as-is, candidates for cleanup)

- `apex_a` → 192.64.119.11 (Namecheap parking IP) and `www_cname` → `parkingpage.namecheap.com` are leftovers from before the site moved to Workers. Worker routes intercept the actual traffic, so these don't affect the live site. Safe to remove once confirmed.
- `ns_1` / `ns_2` records pointing at `dns{1,2}.registrar-servers.com` — in-zone NS records are vestigial since delegation actually happens at the registrar (Namecheap). Cosmetic.

## State

Stored in Storj bucket `nickvigilante-tfstate`, key `cloudflare/nickvigilante-com/terraform.tfstate`. State locking uses S3 conditional writes via the `s3` backend's `use_lockfile = true`.

To inspect state directly:

```bash
aws s3 ls s3://nickvigilante-tfstate/cloudflare/nickvigilante-com/ --endpoint-url https://gateway.storjshare.io
```

## Token rotation

When rotating the Cloudflare API token:

1. Create the new token in the dashboard with the same permissions (don't delete the old one yet).
2. Update `~/.cf-opentofu.env` with the new value.
3. Run `tofu plan` — if it succeeds with no auth errors, the new token works.
4. Revoke the old token in the dashboard.

Same pattern for the Storj S3 credentials.
