terraform {
  backend "s3" {
    bucket = "terraform-state-scb-bucket"
    key    = "aws-s3/terraform.tfstate"
    region = "ap-southeast-1"
  }
  # Only allow Terraform version 12. Note that if you upgrade to a newer version, Terraform won't allow you to use an
  # older version, so when you upgrade, you should upgrade everyone on your team and your CI servers all at once.
  # also do not use Terraform version 11 as that will be failed
  required_version = ">= 0.13.0"
}

provider "aws" {
  region = var.region
  # Provider version 2.X series is the latest, but has breaking changes with 1.X series.
  version = "~> 2.6"
}