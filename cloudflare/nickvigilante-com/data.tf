data "cloudflare_zone" "this" {
  zone_id = var.cloudflare_zone_id
}

output "zone_name" {
  description = "Sanity check that the provider can read the zone."
  value       = data.cloudflare_zone.this.name
}
