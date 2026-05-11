resource "cloudflare_dns_record" "apex_a" {
  zone_id  = var.cloudflare_zone_id
  name     = "nickvigilante.com"
  type     = "A"
  content  = "192.64.119.11"
  proxied  = true
  tags     = []
  ttl      = 1
  settings = {}
}

resource "cloudflare_dns_record" "www_cname" {
  zone_id = var.cloudflare_zone_id
  name    = "www.nickvigilante.com"
  type    = "CNAME"
  content = "parkingpage.namecheap.com"
  proxied = true
  tags    = []
  ttl     = 1
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "ns_1" {
  zone_id  = var.cloudflare_zone_id
  name     = "nickvigilante.com"
  type     = "NS"
  content  = "dns1.registrar-servers.com"
  proxied  = false
  tags     = []
  ttl      = 1
  settings = {}
}

resource "cloudflare_dns_record" "ns_2" {
  zone_id  = var.cloudflare_zone_id
  name     = "nickvigilante.com"
  type     = "NS"
  content  = "dns2.registrar-servers.com"
  proxied  = false
  tags     = []
  ttl      = 1
  settings = {}
}

resource "cloudflare_dns_record" "dmarc" {
  zone_id  = var.cloudflare_zone_id
  name     = "_dmarc.nickvigilante.com"
  type     = "TXT"
  content  = "\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s;\""
  proxied  = false
  tags     = []
  ttl      = 1
  settings = {}
}

resource "cloudflare_dns_record" "dkim_wildcard" {
  zone_id  = var.cloudflare_zone_id
  name     = "*._domainkey.nickvigilante.com"
  type     = "TXT"
  content  = "\"v=DKIM1; p=\""
  proxied  = false
  tags     = []
  ttl      = 1
  settings = {}
}

resource "cloudflare_dns_record" "spf" {
  zone_id  = var.cloudflare_zone_id
  name     = "nickvigilante.com"
  type     = "TXT"
  content  = "\"v=spf1 -all\""
  proxied  = false
  tags     = []
  ttl      = 1
  settings = {}
}

