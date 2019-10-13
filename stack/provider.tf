
terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  shared_credentials_file = "~/.aws/config"
  profile = "latam-sandbox"
  region = "us-east-1"
  max_retries = 1
}
