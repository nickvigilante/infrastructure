variable "coder_url" {
  description = "Base URL of the Coder deployment."
  type        = string
  default     = "https://coder.vigihome.net"
}

variable "coder_organization" {
  description = "Name of the Coder organization that owns the MCP servers. Only used to build import IDs."
  type        = string
  default     = "coder"
}

# The three variables below hold secrets. They are ephemeral, so OpenTofu never
# writes them to state or plan files: the provider token is consumed at
# configure time and the other two only feed write-only (*_wo) attributes.

variable "coder_session_token" {
  description = "Session token of a Coder admin (`coder tokens create`). Needs permission to manage MCP server configs."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "raindrop_oauth_client_secret" {
  description = "Client secret of the Raindrop app registered for Coder. Raindrop rejects dynamic client registration, so the client is created by hand."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "home_assistant_mcp_token" {
  description = "Home Assistant long-lived access token that Coder sends to the MCP endpoint. Home Assistant has no dynamic client registration, so this is a static credential."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "raindrop_oauth_client_id" {
  description = "Client ID of the Raindrop app registered for Coder. An identifier, not a secret, but kept out of the repo like the rest."
  type        = string
  sensitive   = true
}
