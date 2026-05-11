# Tailnet DNS — Global Nameserver(s) for the tailnet.
# Devices that accept Tailscale DNS will forward all non-MagicDNS queries here.
# Pi-hole on gandalf handles ad-blocking + local DNS records (pi.hole,
# jellyfin.home, vigilan.tube).
resource "tailscale_dns_nameservers" "global" {
  nameservers = [
    var.homelab_dns_nameserver_ip,
  ]
}

# MagicDNS lets devices reach each other by short name (e.g. gandalf,
# macbook-pro) without configuring DNS suffixes. Default-on in admin UI but
# made explicit here.
resource "tailscale_dns_preferences" "main" {
  magic_dns = true
}

# Tailnet policy file. Codifies the current default-allow stance and adds
# forward-looking structure (tag:homelab, SSH for tagged servers) that no-ops
# until devices actually advertise the tag.
#
# DO NOT tighten the `*:*` rule in the same change that introduces tagging.
# Switching to a restrictive policy before any device wears tag:homelab will
# leave the operator unable to reach gandalf over Tailscale. Sequence:
#   1. (this resource) Codify allow-all + tagOwners + SSH-to-tag-homelab.
#   2. Advertise tag:homelab on gandalf (`tailscale up --advertise-tags=tag:homelab`)
#      and approve the tag in the admin UI.
#   3. Replace the `*:*` rule with restrictive admin/tag-scoped rules.
resource "tailscale_acl" "main" {
  acl = jsonencode({
    tagOwners = {
      # Servers in the home lab (gandalf today, Pis later). Only tailnet
      # admins can apply this tag — prevents a random tailnet member from
      # spoofing a homelab node.
      "tag:homelab" = ["autogroup:admin"]
    }

    acls = [
      # Phase 1: keep the default-allow rule so nothing breaks for current
      # devices. Replace with restrictive rules in a follow-up PR after
      # gandalf is tagged.
      {
        action = "accept"
        src    = ["*"]
        dst    = ["*:*"]
      },
    ]

    ssh = [
      # Tailscale SSH default: members can SSH into their own devices
      # (the "check" action requires reauth). Carried over from the
      # admin UI default.
      {
        action = "check"
        src    = ["autogroup:member"]
        dst    = ["autogroup:self"]
        users  = ["autogroup:nonroot", "root"]
      },
      # Forward-looking: members can SSH into homelab-tagged servers as
      # `nickv` or `root`. No-op until a device wears tag:homelab.
      {
        action = "accept"
        src    = ["autogroup:member"]
        dst    = ["tag:homelab"]
        users  = ["nickv", "root"]
      },
    ]

    nodeAttrs = [
      # Tailscale Funnel — let members expose their own devices to the
      # public internet. Carried over from the admin UI default.
      {
        target = ["autogroup:member"]
        attr   = ["funnel"]
      },
    ]
  })
}
