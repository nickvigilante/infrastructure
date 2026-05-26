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

    # Native S3 state locking: writes a `<key>.tflock` object via a
    # conditional PutObject, deletes it when the run finishes. DynamoDB-free
    # (Storj has no DynamoDB), so this is the lock mechanism that works here.
    # Matches the cloudflare backend. The state grant's Write+Delete cover it.
    use_lockfile = true
  }
}
