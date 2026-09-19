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

## Secrets

The static secrets live in Bitwarden Secrets Manager, and `./tofu.sh` runs `tofu` with them injected for that one command.
The Coder admin token is minted for the run and revoked when it exits, or expires on its own after an hour if the revoke fails.
Nothing is written to disk, and the secret variables are ephemeral and only feed write-only attributes, so they never reach state or a saved plan.

### Once, in Bitwarden Secrets Manager

1. Create a project named `homelab-iac`.
   Keep it separate from `homelab`, whose secrets the cluster reads through ESO.

2. Add three secrets to it.
   Secret names become environment variable names, so spell them exactly like this.

   | Secret                                | Value                                                                                      |
   | ------------------------------------- | ------------------------------------------------------------------------------------------ |
   | `TF_VAR_raindrop_oauth_client_id`     | Client ID of the Raindrop app registered for Coder (app.raindrop.io/settings/integrations) |
   | `TF_VAR_raindrop_oauth_client_secret` | Client secret of that app                                                                  |
   | `TF_VAR_home_assistant_mcp_token`     | Home Assistant long-lived access token (profile → Security)                                |

3. Create a machine account named `operator` with Read access to `homelab-iac` only.

4. Create one access token for it per computer, named for the computer, with an expiry.
   A lost machine then costs one revocation.

### On each computer

1. Install `bws`, `jq`, and the `coder` CLI, and log in to Coder as an admin with `coder login`.
2. Store that computer's access token where the wrapper looks for it, in this order.
   - The `BWS_ACCESS_TOKEN` environment variable.
   - On macOS, a Keychain item.
     `security add-generic-password -U -a "$USER" -s homelab-bws-operator -w` prompts for the token, so it never lands in your shell history.
   - A file at `~/.config/bws/operator-token` with mode 600.
3. Load the Storj state credentials into your shell: `set -a && source ~/.homelab-opentofu.env && set +a`.

Then use the wrapper in place of `tofu`: `./tofu.sh init`, `./tofu.sh plan`, `./tofu.sh apply`.
It finds the `homelab-iac` project by name, checks that all three secrets exist, and reports any that are missing by name only.

## First apply

The order matters, because Coder runs OAuth discovery from inside its own pod at creation time.

1. Merge homelab#204's `CODER_MCP_ALLOWED_PRIVATE_CIDRS` change and let Flux reconcile it.
   Without it Coder's SSRF guard blocks Outline and Home Assistant, and creating them fails.
2. In Outline, enable MCP under Settings → Workspace → AI.
3. In Home Assistant, check the MCP Server integration is set up and expose only the entities you want agents to see to Assist.
   Then create the long-lived access token and store it as `TF_VAR_home_assistant_mcp_token` in Bitwarden.
4. Confirm the Raindrop server exists in Coder with the slug `raindrop`, and that its Raindrop app's redirect URL is still Coder's callback for it.
   `imports.tf` adopts it rather than recreating it, because recreating would change the server ID in the callback URL.
5. Run `./tofu.sh init` and `./tofu.sh plan`, and review the plan before `./tofu.sh apply`.
6. In a Coder Agents chat, turn each server on, and click Auth for the OAuth ones (Todoist, Outline, Raindrop).

Expect the first plan to import Raindrop and create the other three.
Raindrop will also show an in-place update for the tool deny list and the write-only secret.
Stop and investigate if the plan changes its URL, client ID, or token URL, because those invalidate every user's stored token.

## Day to day

- **Rotate a secret:** change the value in Bitwarden, then bump the matching `*_wo_version` in `mcp_servers.tf`.
  Write-only values are not tracked in state, so the version number is what tells OpenTofu to send it again.
- **Redo OAuth discovery:** Coder only runs discovery when a server is created.
  Use `./tofu.sh apply -replace=coderd_agents_mcp_server.<name>`, which also drops users' stored tokens.
- **Add a server:** copy a block in `mcp_servers.tf`.
  Try `auth_type = "oauth2"` with no OAuth fields first, since a failed discovery rejects the create and leaves nothing behind.
  Fall back to a static header, or a hand-registered client as with Raindrop, when the provider doesn't allow dynamic registration.
- **Provider stability:** `coderd_agents_mcp_server` is experimental upstream and needs Coder 2.37.0 or later.
  The provider is pinned to `0.0.x`, so review its changelog before bumping.
