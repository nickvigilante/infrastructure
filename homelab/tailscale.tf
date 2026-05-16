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

# Tailnet policy file.
#
# Two ACL rules: (1) tailnet members reach homelab-tagged servers on any
# port — that's how you reach Jellyfin/Pi-hole/Uptime Kuma on gandalf from
# your laptop or phone over Tailscale; (2) homelab-tagged servers reach
# each other for intra-cluster traffic (k3s agent join, kubelet, etc.).
#
# No `*:*` allow-all rule. A device that isn't tagged `tag:homelab` and
# isn't a tailnet member can't reach anything on the homelab side. New
# servers added later need both: (a) `sudo tailscale up
# --advertise-tags=tag:homelab` and (b) an entry in `tagOwners` if a new
# tag is introduced.
resource "tailscale_acl" "main" {
  acl = jsonencode({
    tagOwners = {
      # Servers in the home lab (gandalf today, Pis later). Only tailnet
      # admins can apply this tag — prevents a random tailnet member from
      # spoofing a homelab node.
      "tag:homelab" = ["autogroup:admin"]
    }

    acls = [
      # Tailnet members (you, plus anyone you ever share into the tailnet)
      # reach homelab-tagged servers on any port. Covers Jellyfin / Pi-hole
      # / Uptime Kuma access from your laptop and phone via Tailscale.
      {
        action = "accept"
        src    = ["autogroup:member"]
        dst    = ["tag:homelab:*"]
      },
      # Homelab nodes can talk to each other (gandalf today, future Pi
      # workers tomorrow). Necessary for k3s agent join, kubelet API,
      # cluster-internal traffic over the tailnet.
      {
        action = "accept"
        src    = ["tag:homelab"]
        dst    = ["tag:homelab:*"]
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
      # Members can SSH into homelab-tagged servers as `nickv` or `root`.
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

    # autoApprovers — routes that don't need a human in the admin UI
    # to click "Approve" on. Scoped narrowly: any device tagged
    # tag:homelab that advertises itself as an exit node is auto-
    # approved. Lets us re-provision pi-zero-exit (or any other home-
    # lab box) with `sudo tailscale up --advertise-exit-node` and have
    # it become a usable exit node immediately, with no admin click.
    #
    # Tag-gated by design: only nodes we've already vouched for (via
    # the auth-key + ansible flow that applies tag:homelab) can self-
    # approve exit routing. A random tailnet member device can't.
    autoApprovers = {
      exitNode = ["tag:homelab"]
    }
  })
}
