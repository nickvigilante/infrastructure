resource "cloudflare_ruleset" "zone_custom_firewall" {
  zone_id     = var.cloudflare_zone_id
  name        = "default"
  description = ""
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules = [
    {
      ref         = "[CF AI Audit]"
      description = "AI Crawl Control - Block AI bots by User Agent"
      expression  = "(http.request.uri.path ne \"/robots.txt\" and ((http.user_agent contains \"Applebot\") or (http.user_agent contains \"archive.org_bot\") or (http.user_agent contains \"bingbot\") or (http.user_agent contains \"ChatGPT-User\") or (http.user_agent contains \"DuckAssistBot\") or (http.user_agent contains \"Googlebot\") or (http.user_agent contains \"Manus-User\") or (http.user_agent contains \"meta-externalfetcher\") or (http.user_agent contains \"MistralAI-User\") or (http.user_agent contains \"OAI-SearchBot\") or (http.user_agent contains \"Perplexity-User\") or (http.user_agent contains \"PerplexityBot\") or (http.user_agent contains \"ProRataInc\") or (http.user_agent contains \"Terracotta\")))"
      action      = "block"
      enabled     = true
    },
    {
      ref         = "c9098adab50747ea960a4ada7f544d69"
      description = "Dotfiles - allow curl/bash one-liner install"
      expression  = "(http.request.uri.path eq \"/dotfiles\")"
      action      = "skip"
      action_parameters = {
        phases = [
          "http_request_sbfm",
          "http_request_firewall_managed",
        ]
        products = [
          "bic",
          "hot",
          "rateLimit",
          "securityLevel",
          "uaBlock",
          "waf",
          "zoneLockdown",
        ]
      }
      logging = {
        enabled = true
      }
      enabled = true
    },
  ]
}
