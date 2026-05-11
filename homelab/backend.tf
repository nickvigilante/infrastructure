terraform {
  backend "s3" {
    bucket = "nickvigilante-tfstate"
    key    = "homelab/terraform.tfstate"
    region = "us-east-1" # Storj ignores region but the S3 SDK requires it

    endpoints = {
      s3 = "https://gateway.storjshare.io"
    }

    # Storj's S3 gateway is path-style and doesn't expose AWS account metadata.
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}
