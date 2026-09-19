# coder

OpenTofu context for the MCP servers registered with Coder Agents on `coder.vigihome.net`.
Coder keeps these registrations in its database, so this context is what makes them reviewable and reproducible.
Tracking issue: [homelab#204](https://github.com/nickvigilante/homelab/issues/204).

## What's managed

| Server         | URL                                           | Auth                                | Why                                                                      |
| -------------- | --------------------------------------------- | ----------------------------------- | ------------------------------------------------------------------------ |
| Todoist        | `https://ai.todoist.net/mcp`                  | OAuth, discovered on create         | Todoist allows dynamic client registration from any client.              |
| Outline        | `https://docs.vigihome.net/mcp`               | OAuth, discovered on create         | Outline serves its own OAuth metadata and registration endpoint.         |
| Home Assistant | `https://home-assistant.vigihome.net/api/mcp` | Static long-lived token in a header | Home Assistant has no dynamic client registration.                       |
| Raindrop       | `https://api.raindrop.io/rest/v2/ai/mcp`      | OAuth, hand-registered client       | Raindrop advertises registration but only allows pre-registered clients. |

Every server is `default_off`, so users opt in per chat.
Destructive tools are denied where the upstream tool names are known.
The lists come from each project's docs and source, so check them against the server's live tool list when you add or change one.

## Applies locally only

Coder is only reachable over the tailnet, so GitHub-hosted runners can't plan or apply this context.
It is deliberately not part of the `homelab-plan` and `homelab-apply` workflows.
Run it from a machine on the tailnet.

## Env vars required at apply time

Source `~/.homelab-opentofu.env`, which already exports the Storj state credentials, and add:

```bash
# Session token of a Coder admin, created with `coder tokens create`.
export TF_VAR_coder_session_token="..."

# The Raindrop app registered for Coder (https://app.raindrop.io/settings/integrations).
export TF_VAR_raindrop_oauth_client_id="..."
export TF_VAR_raindrop_oauth_client_secret="..."

# Home Assistant long-lived access token (profile -> Security).
export TF_VAR_home_assistant_mcp_token="..."
```

The values belong in Bitwarden with the rest of the homelab secrets, never in this repo.
The secret variables are ephemeral and only feed write-only attributes, so they never reach state or a saved plan.

## First apply

The order matters, because Coder runs OAuth discovery from inside its own pod at creation time.

1. Merge homelab#204's `CODER_MCP_ALLOWED_PRIVATE_CIDRS` change and let Flux reconcile it.
   Without it Coder's SSRF guard blocks Outline and Home Assistant, and creating them fails.
2. In Outline, enable MCP under Settings → Workspace → AI.
3. In Home Assistant, check the MCP Server integration is set up and expose only the entities you want agents to see to Assist.
   Then create the long-lived access token.
4. Confirm the Raindrop server exists in Coder with the slug `raindrop`, and that its Raindrop app's redirect URL is still Coder's callback for it.
   `imports.tf` adopts it rather than recreating it, because recreating would change the server ID in the callback URL.
5. Load the env vars, then `tofu init`, `tofu plan`, and review the plan before `tofu apply`.
6. In a Coder Agents chat, turn each server on, and click Auth for the OAuth ones (Todoist, Outline, Raindrop).

Expect the first plan to import Raindrop and create the other three.
Raindrop will also show an in-place update for the tool deny list and the write-only secret.
Stop and investigate if the plan changes its URL, client ID, or token URL, because those invalidate every user's stored token.

## Day to day

- **Rotate a secret:** change the value in your env file, then bump the matching `*_wo_version` in `mcp_servers.tf`.
  Write-only values are not tracked in state, so the version number is what tells OpenTofu to send it again.
- **Redo OAuth discovery:** Coder only runs discovery when a server is created.
  Use `tofu apply -replace=coderd_agents_mcp_server.<name>`, which also drops users' stored tokens.
- **Add a server:** copy a block in `mcp_servers.tf`.
  Try `auth_type = "oauth2"` with no OAuth fields first, since a failed discovery rejects the create and leaves nothing behind.
  Fall back to a static header, or a hand-registered client as with Raindrop, when the provider doesn't allow dynamic registration.
- **Provider stability:** `coderd_agents_mcp_server` is experimental upstream and needs Coder 2.37.0 or later.
  The provider is pinned to `0.0.x`, so review its changelog before bumping.
