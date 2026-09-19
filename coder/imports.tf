# Raindrop and Outline were created by hand in the Coder UI. A server's ID is
# baked into its OAuth callback URL and into every user's stored token, so
# deleting and recreating one would break both. Adopt the existing servers
# instead of creating new ones.
#
# Import IDs are "<organization name>/<slug>". These blocks are no-ops once the
# resources are in state, so they are safe to leave in place.
#
# Todoist and Home Assistant are created by this context. If one of them was
# already created by hand, add an import block for it here before the first
# apply, or delete it in the Coder UI so OpenTofu can create it.
import {
  to = coderd_agents_mcp_server.raindrop
  id = "${var.coder_organization}/raindrop"
}

import {
  to = coderd_agents_mcp_server.outline
  id = "${var.coder_organization}/outline"
}
