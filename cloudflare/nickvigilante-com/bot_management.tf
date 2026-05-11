resource "cloudflare_bot_management" "this" {
  zone_id               = var.cloudflare_zone_id
  enable_js             = true
  fight_mode            = true
  ai_bots_protection    = "block"
  crawler_protection    = "enabled"
  is_robots_txt_managed = true
}
