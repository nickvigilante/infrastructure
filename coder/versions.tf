terraform {
  # The *_wo attributes on coderd_agents_mcp_server are write-only, which
  # needs OpenTofu 1.11+. That keeps every secret out of state.
  required_version = ">= 1.11.0"

  required_providers {
    coderd = {
      source = "coder/coderd"
      # coderd_agents_mcp_server is experimental upstream and needs Coder
      # 2.37.0+. Stay on 0.0.x until the resource stabilises.
      version = "~> 0.0.26"
    }
  }
}
