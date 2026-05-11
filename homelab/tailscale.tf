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
