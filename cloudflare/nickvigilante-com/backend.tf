terraform {
  backend "s3" {
    bucket = "nickvigilante-tfstate"
    key    = "cloudflare/nickvigilante-com/terraform.tfstate"
    region = "global"

    endpoints = {
      s3 = "https://gateway.storjshare.io"
    }

    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true

    use_lockfile = true
  }
}
