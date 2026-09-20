# MCP servers for Coder Agents (AI Settings -> Coder Agents -> MCP servers).
#
# Every server is `default_off`: users opt in per chat, so nothing is injected
# into a conversation that did not ask for it.
#
# Coder runs OAuth discovery and dynamic client registration only when a server
# is *created* with auth_type = "oauth2" and no manual endpoints. Updates never
# re-run it. To redo discovery, replace the resource:
#   ./tofu.sh apply -replace=coderd_agents_mcp_server.<name>

# Todoist -- hosted by Todoist, per-user OAuth.
#
# Todoist's dynamic client registration is open to any client, so discovery
# works with every OAuth field left empty. Scopes are set explicitly on purpose:
# left blank, discovery copies every scope Todoist advertises (billing,
# workspaces, delete) into the config instead of the one the MCP resource asks
# for.
resource "coderd_agents_mcp_server" "todoist" {
  display_name = "Todoist"
  slug         = "todoist"
  description  = "Tasks, projects, and comments in Todoist."
  icon_url     = "https://todoist.com/favicon.ico"
  url          = "https://ai.todoist.net/mcp"

  auth_type      = "oauth2"
  oauth2_scopes  = "data:read_write"
  tool_deny_list = ["delete-object"]
  availability   = "default_off"
  enabled        = true
  transport      = "streamable_http"
}

# Outline -- self-hosted at docs.vigihome.net, per-user OAuth.
#
# Outline advertises RFC 9728/8414 metadata and dynamic client registration on
# its own /mcp endpoint, so discovery works with every OAuth field left empty.
# The URL is the public hostname, not cluster-internal service DNS: Outline
# forces HTTPS and advertises its public URL in its OAuth metadata, so an
# in-cluster HTTP URL would break discovery.
#
# MCP must be switched on in Outline first (Settings -> Workspace -> AI), or
# creating this resource fails discovery. Coder also has to be allowed to reach
# gandalf's private addresses (CODER_MCP_ALLOWED_PRIVATE_CIDRS, homelab #204).
#
# This server was created by hand before this context managed it; see
# imports.tf.
resource "coderd_agents_mcp_server" "outline" {
  display_name = "Outline"
  slug         = "outline"
  description  = "Search and edit the homelab wiki."
  icon_url     = "https://www.getoutline.com/favicon.png"
  url          = "https://docs.vigihome.net/mcp"

  auth_type      = "oauth2"
  tool_deny_list = ["delete_document"]
  availability   = "default_off"
  enabled        = true
  transport      = "streamable_http"
}

# Home Assistant -- HAOS on a separate Pi, static long-lived token.
#
# Home Assistant has no dynamic client registration (its OAuth is IndieAuth),
# so this is a shared static credential: every Coder user acts as the token's
# owner. What the agent can do is bounded by the entities exposed to Assist in
# Home Assistant, not by anything here. Reached through Traefik at the public
# hostname, which is the path Home Assistant's trusted_proxies already covers.
#
# The URL pins the Assist API. The plain /api/mcp path is ambiguous once more
# than one LLM API exists, and Home Assistant only lets administrators connect
# to any API other than Assist.
resource "coderd_agents_mcp_server" "home_assistant" {
  display_name = "Home Assistant"
  slug         = "home-assistant"
  description  = "Read and control the entities exposed to Assist."
  icon_url     = "https://www.home-assistant.io/images/favicon-192x192.png"
  url          = "https://home-assistant.vigihome.net/api/mcp/assist"

  auth_type                = "api_key"
  api_key_header           = "Authorization"
  api_key_value_wo         = "Bearer ${var.home_assistant_mcp_token}"
  api_key_value_wo_version = 1

  availability = "default_off"
  enabled      = true
  transport    = "streamable_http"
}

# Raindrop -- hosted by Raindrop, per-user OAuth with a hand-registered client.
#
# Raindrop advertises a registration endpoint but only allows pre-registered
# clients to use it, so discovery cannot work. The client comes from an app
# created at https://app.raindrop.io/settings/integrations whose redirect URL
# is Coder's callback for this server:
#   <coder url>/api/experimental/mcp/servers/<server id>/oauth2/callback
# This server was created by hand before this context existed; see imports.tf.
resource "coderd_agents_mcp_server" "raindrop" {
  display_name = "Raindrop"
  slug         = "raindrop"
  description  = "Search and organise Raindrop bookmarks."
  icon_url     = "https://raindrop.io/favicon.ico"
  url          = "https://api.raindrop.io/rest/v2/ai/mcp"

  auth_type                       = "oauth2"
  oauth2_client_id                = var.raindrop_oauth_client_id
  oauth2_client_secret_wo         = var.raindrop_oauth_client_secret
  oauth2_client_secret_wo_version = 1
  oauth2_auth_url                 = "https://api.raindrop.io/v2/oauth/authorize"
  oauth2_token_url                = "https://api.raindrop.io/v2/oauth/access_token"

  tool_deny_list = [
    "delete_bookmarks",
    "delete_collections",
    "delete_highlights",
    "delete_tags",
  ]
  availability = "default_off"
  enabled      = true
  transport    = "streamable_http"
}

# Kubernetes -- read-only view of the gandalf cluster, in-cluster.
#
# Served by k8s/claude-mcp in the homelab repo (#186). It is reachable only from
# the coder namespace, which is the access gate, so there is no auth here. The
# server runs as a `view`-bound ServiceAccount with read_only on and Secrets
# denied. Coder's SSRF guard allows the address through
# CODER_MCP_ALLOWED_PRIVATE_CIDRS (10.43.0.201/32).
resource "coderd_agents_mcp_server" "kubernetes" {
  display_name = "Kubernetes"
  slug         = "kubernetes"
  description  = "Read-only view of the gandalf cluster: workloads, events, and pod logs."
  url          = "http://kubernetes-mcp.claude-mcp.svc.cluster.local:8080/mcp"

  auth_type    = "none"
  availability = "default_off"
  enabled      = true
  transport    = "streamable_http"
}

# Grafana -- read-only dashboards and PromQL, in-cluster.
#
# Served by k8s/claude-mcp in the homelab repo (#184). Same access gate as the
# Kubernetes server. It reaches Grafana with a Viewer service-account token
# held in the cluster, not by Coder (10.43.0.200/32 is allowlisted).
resource "coderd_agents_mcp_server" "grafana" {
  display_name = "Grafana"
  slug         = "grafana"
  description  = "Read-only Grafana dashboards and Prometheus queries."
  url          = "http://grafana-mcp.claude-mcp.svc.cluster.local:8000/mcp"

  auth_type    = "none"
  availability = "default_off"
  enabled      = true
  transport    = "streamable_http"
}
