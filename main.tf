module "hourly" {
  source = "./aws-s3"
  # if reference it from other repo use below one
  //  source = "git::git@github.com:Greg215/terraform-aws-s3.git//aws-s3?ref=master"

  bucket_name = var.bucket_name_hourly

  versioning_enabled = true
  object_lock_configuration = {
    mode  = "GOVERNANCE"
    days  = 366
    years = null
  }
}

module "daily" {
  source = "./aws-s3"

  bucket_name = var.bucket_name_daily

  s3_replication_rules = [
    {
      id     = "replication-test"
      status = "Enabled"
      prefix = "/main"
    }
  ]
}

module "weekly" {
  source = "./aws-s3"

  bucket_name = var.bucket_name_weekly

  grants = [
    {
      id          = null
      type        = "Group"
      permissions = ["READ", "WRITE"]
      uri         = "http://acs.amazonaws.com/groups/s3/LogDelivery"
    },
  ]
}