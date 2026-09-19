# The Raindrop server was created by hand in the Coder UI, and its server ID is
# baked into the OAuth callback URL registered with Raindrop. Deleting and
# recreating it would change that ID and break the registration, so adopt the
# existing server instead of creating a new one.
#
# Import IDs are "<organization name>/<slug>". This block is a no-op once the
# resource is in state, so it is safe to leave in place.
#
# Todoist, Outline, and Home Assistant are created by this context. If one of
# them was already created by hand, add an import block for it here before the
# first apply, or delete it in the Coder UI so OpenTofu can create it.
import {
  to = coderd_agents_mcp_server.raindrop
  id = "${var.coder_organization}/raindrop"
}
