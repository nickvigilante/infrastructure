# GitHub Configuration Management via OpenTofu — Design & Plan

**Status:** design approved 2026-09-27. Chunk A shipped separately (see below); chunks B–F not started.

**Goal:** Manage GitHub repository configuration (branch protection, merge settings, Actions
permissions) as code via OpenTofu, across both the personal `nickvigilante` namespace and the
`klavyn` organization, replacing/extending the existing `homelab/github.tf` context which only
covers `nickvigilante`.

**Architecture:** A new `github/` OpenTofu context (sibling to `homelab/`, `cloudflare/`,
`coder/`), with its own Storj-backed state. Two aliased `github` provider configurations
(`personal`, `klavyn`) share one GitHub App, authenticating via two separate installations. A
reusable `modules/github-repo/` module encapsulates one repo's resources; each managed repo gets
its own file under `repos/personal/` or `repos/klavyn/` that instantiates the module by merging a
shared `repo_defaults` template with that repo's specific overrides. Branch protection moves from
classic `github_branch_protection` to `github_repository_ruleset`, adding an explicit, audited
`bypass_actors` mechanism in place of today's blanket `enforce_admins = false`. `homelab/github.tf`
is retired once its resources have been migrated into `github/`.

**Tech Stack:** OpenTofu 1.10+, `integrations/github` provider ~> 6.5, Storj S3 Gateway-MT
(`gateway.storjshare.io`, bucket `nickvigilante-tfstate`), same GitHub App used by `homelab/`
(`app_auth`, two installations).

**Repo decision:** This lives in `nickvigilante/infrastructure`, in a new top-level `github/`
context, not folded into `homelab/`. `homelab/` is a physical-homelab concern (Tailscale, DNS,
k3s); repo/org configuration is unrelated and its state/blast-radius shouldn't grow homelab's.

______________________________________________________________________

## Decisions locked in (from design discussion)

- **Root layout:** new `github/` context, not `homelab/`, not split per-owner into two contexts.
  One state file, one plan/apply CI pair, covers both `personal` and `klavyn` provider aliases.
- **Klavyn auth:** the existing GitHub App gets installed on the `klavyn` org as a second,
  independent installation. Same App ID / PEM, a second `installation_id` variable.
- **Per-repo override location:** inside this `infrastructure` repo — one `.tf` file per managed
  repo (e.g. `repos/personal/dotfiles.tf`), not config living inside each managed repo's own
  codebase. Centralized, matching every other context in this repo.
- **Branch protection mechanism:** migrate everything (all 10 existing `nickvigilante` repos, plus
  every `klavyn` repo) from classic `github_branch_protection` to `github_repository_ruleset`.
  Accepted as a one-time lift in exchange for one consistent mechanism and real bypass-actor
  auditing.
- **Actions-permissions hardening (`default_workflow_permissions` = `read`,
  `can_approve_pull_request_reviews` = `false`):** klavyn only, via the org-level
  `github_actions_organization_workflow_permissions` resource. The provider has no repo-level
  equivalent, so personal-namespace repos don't get this via Tofu for now — tracked in
  [nickvigilante/infrastructure#28](https://github.com/nickvigilante/infrastructure/issues/28).

______________________________________________________________________

## Tasks

### Chunk A: Enable auto-merge — DONE

- `homelab/locals.tf`: `repo_defaults.allow_auto_merge` flipped `false` → `true`.
- Shipped independently of everything below; see
  [PR #29](https://github.com/nickvigilante/infrastructure/pull/29).

### Chunk B: Scaffold the `github/` context

No live resources yet — this chunk only stands up structure, so it carries no risk to real state.

- `github/backend.tf` — Storj S3 backend, key `github/terraform.tfstate`, same pattern as
  `homelab/backend.tf` (`use_lockfile = true`, path-style, region ignored).
- `github/versions.tf` — `required_version >= 1.10.0`, `integrations/github ~> 6.5`.
- `github/variables.tf` — `github_app_id`, `github_app_pem_file`, `github_owner_personal`
  (default `"nickvigilante"`), `github_owner_klavyn` (default `"klavyn"`),
  `github_app_installation_id_personal`, `github_app_installation_id_klavyn`.
- `github/providers.tf` — two aliased `github` provider blocks (`personal`, `klavyn`), each with
  its own `app_auth { installation_id = ... }`.
- `github/repo_defaults.tf` — `locals.repo_defaults`, the shared template, ported from
  `homelab/locals.tf`'s `repo_defaults` map but expressed for ruleset fields instead of
  `github_branch_protection` fields (see Chunk D for the field mapping).
- `github/modules/github-repo/` — reusable module. Inputs: `name`, `settings` (object covering
  every `repo_defaults` field plus per-repo overrides). Resources: `github_repository`,
  `github_repository_vulnerability_alerts` (conditional), `github_repository_dependabot_security_updates`
  (new addition, conditional, default on), `github_repository_ruleset` (main branch, conditional
  on `protect_main`). Outputs: repo name, node ID, whether protected.
- `github/outputs.tf` — aggregate outputs (managed repo names, protected repo names), mirroring
  `homelab/outputs.tf`.
- `.github/workflows/github-plan.yml` / `github-apply.yml` — copy the `homelab-plan.yml` /
  `homelab-apply.yml` pattern exactly: path-filtered on `github/**`, `github-plan` reports a
  required status check even when skipped (so it never blocks unrelated PRs), `github-apply` is
  `workflow_dispatch`-only behind a `github-apply` environment requiring manual approval.
- `tofu init` (backend included this time) + `tofu validate` — confirms the new state object gets
  created empty. No `tofu apply` in this chunk (nothing to apply yet — zero resources defined
  until Chunk C/E add real repo files).

### Chunk C: Migrate personal-namespace resources out of `homelab/` — state surgery

This is the one chunk that touches live-managed GitHub resources' Terraform state and needs to be
done carefully, together, not run unattended:

1. `tofu state pull > homelab.tfstate.backup` (and equivalent for the new `github/` state) before
   touching anything — keep both backups until the migration is verified.
2. For every `github_*` resource currently in `homelab/`'s state (`github_repository.managed`,
   `github_repository_vulnerability_alerts.alerts`, `github_actions_secret.*`,
   `github_repository_environment.homelab_apply`, `data.github_user.self`), write the equivalent
   config in the new `github/` layout (module-per-repo-file for repos; the Actions-secrets and
   environment resources move to `github/` too, since they configure the `infrastructure` repo
   object that now lives there).
3. `tofu state mv -state=homelab.tfstate.backup -state-out=<github-state>` per resource address —
   or the equivalent pulled/pushed against the real backends — confirmed by a `tofu plan` in
   `github/` showing **zero** changes (no create/destroy) before touching `homelab/`'s copy.
4. Once `github/`'s plan is clean, remove the migrated resources from `homelab/`'s config and
   state (`tofu state rm`), then `tofu plan` in `homelab/` also showing zero changes.
5. `homelab-plan.yml`/`homelab-apply.yml` CI secrets: the App/Tailscale/AWS secrets currently set
   as `github_actions_secret` resources move with `infrastructure`'s repo object into `github/`;
   confirm both `homelab-plan` and `github-plan` workflows still have what they need afterward.
6. The `infrastructure` repo's required-status-checks list grows from `["homelab-plan"]` to
   `["homelab-plan", "github-plan"]`.

**Do not proceed to Chunk D until Chunk C's plans are clean in both contexts.**

### Chunk D: Classic branch protection → rulesets, per repo, with no protection gap

Two mechanisms can be active on the same branch simultaneously (GitHub enforces the union), so
migration never leaves a repo unprotected:

1. Add the repo's `github_repository_ruleset` resource (module already does this) and `tofu apply`
   — this creates the ruleset *alongside* the still-live classic `github_branch_protection`.
2. Confirm on GitHub (Settings → Rules) that the ruleset is active and enforcing the expected
   rules.
3. Remove the old `github_branch_protection` resource from `homelab/`'s config (by this point
   already migrated into `github/` per Chunk C) and `tofu apply` again — this destroys only the
   classic protection; the ruleset continues alone.
4. Repeat per repo. After the first one or two confirm the pattern works, later repos can be
   batched.

Field mapping, classic → ruleset (verified against the `integrations/github` provider docs):

| Classic (`github_branch_protection`) | Ruleset (`github_repository_ruleset`) |
| --- | --- |
| `required_pull_request_reviews { required_approving_review_count, dismiss_stale_reviews, require_code_owner_reviews }` | `rules.pull_request { required_approving_review_count, dismiss_stale_reviews_on_push, require_code_owner_review }` |
| `require_conversation_resolution` | `rules.pull_request.required_review_thread_resolution` |
| (implicit — `allow_squash_merge`/`allow_merge_commit`/`allow_rebase_merge` on `github_repository`) | `rules.pull_request.allowed_merge_methods` — **required, min 1 entry**; derive from the same three repo-level merge-method booleans |
| `required_status_checks { strict, contexts = [...] }` | `rules.required_status_checks { strict_required_status_checks_policy = ..., required_check { context = "..." } }` — **`required_check` is a repeated nested block, not a flat list of strings** |
| `allows_deletions = false` | `rules.deletion = true` (plain boolean, not a presence-block) |
| `allows_force_pushes = false` | `rules.non_fast_forward = true` (plain boolean, not a presence-block) |
| `pattern = "main"` | `conditions.ref_name.include = ["~DEFAULT_BRANCH"]`, `conditions.ref_name.exclude = []` |
| `enforce_admins = false` (implicit, blanket bypass) | `bypass_actors { actor_type = "User", actor_id = <your numeric GitHub user ID, e.g. via data.github_user.self.id>, bypass_mode = "always" }` (explicit, audited) |

Also required on every ruleset (no classic-protection equivalent to port from, just required by the
resource itself): top-level `enforcement = "active"`, `target = "branch"`, `name`, `repository`.

### Chunk E: Klavyn onboarding

Blocked on you: install the existing GitHub App on the `klavyn` org and provide its
`installation_id`.

Once available:

- Add `github_app_installation_id_klavyn` value (as a CI secret + local env var, matching the
  `homelab` pattern for the personal installation).
- Populate `repos/klavyn/<name>.tf` for each repo you want managed — first apply for these is a
  plain create/import (nothing manages them yet, no migration needed).
- Add `github_actions_organization_workflow_permissions` (klavyn only) in `github/klavyn.tf`:
  `default_workflow_permissions = "read"`, `can_approve_pull_request_reviews = false`.

### Chunk F: Cleanup

- Delete `homelab/github.tf` once Chunks C and D are fully verified — nothing GitHub-related
  should remain in `homelab/`.
- Remove the now-unused `github` provider/version requirement and `github_*` variables from
  `homelab/providers.tf`, `homelab/versions.tf`, `homelab/variables.tf`.
- Update this repo's top-level `README.md` context overview to list `github/` alongside
  `cloudflare/`, `coder/`, `homelab/`.

______________________________________________________________________

## Decisions worth noting

- **Why a new `github/` context instead of extending `homelab/`:** `homelab/` is a physical-homelab
  concern (Tailscale tailnet, DNS, k3s host configs); GitHub repo/org configuration is unrelated.
  Keeping them together meant every repo added — personal or klavyn — grew homelab's state, CI
  surface, and blast radius for no reason.
- **Why two provider aliases in one root instead of two separate roots:** a single `github`
  provider block is scoped to one owner, so multi-owner management needs either aliases or
  separate roots. One root/state keeps a single `tofu plan`/`apply` covering both owners and
  avoids doubling backend/CI boilerplate; the trade-off is a bad apply could theoretically touch
  both owners' resources in one run, but `tofu plan` review before apply mitigates this the same
  way it already does for the mixed Tailscale+GitHub resources in `homelab/` today.
- **Why one `.tf` file per repo instead of a shared `locals.repos` map (as `homelab/` currently
  does):** explicitly requested — matches "start from a default template, override within that
  repo's own file" rather than editing shared map entries. Trade-off: more files, more
  repetition of the `module` block boilerplate per repo, versus a single dense map. Accepted as
  worth it for the requested editing ergonomics.
- **Why rulesets instead of keeping classic branch protection:** rulesets add an explicit,
  actor-scoped `bypass_actors` mechanism (auditable — GitHub logs when a bypass is used) in place
  of today's blanket `enforce_admins = false`, which lets any admin silently skip protection with
  no record of it happening. Migrating all repos (rather than only new ones) avoids running two
  protection mechanisms long-term.
- **Why Actions-permissions hardening is klavyn-only:** the `integrations/github` provider only
  exposes `default_workflow_permissions`/`can_approve_pull_request_reviews` as an
  *organization*-level resource; there's no repo-level resource, and personal accounts have no
  organization-level concept at all. The threat this setting guards against (an untrusted PR
  hijacking a write-scoped `GITHUB_TOKEN`) matters more for an org that might eventually take
  outside contributions than for solo personal repos with `required_approving_review_count = 0`
  and no untrusted-input workflows today. Tracked for revisit in
  [#28](https://github.com/nickvigilante/infrastructure/issues/28) if the provider adds repo-level
  support, or if a personal repo ever gains outside collaborators.
- **State migration safety (Chunk C):** done via `tofu state mv` with zero-diff `tofu plan`
  verification at each step, never via destroy+recreate, so no live GitHub repository, protection
  rule, or secret is ever actually deleted and recreated by the migration itself.
