# Information
1. This module has been tested on terraform version 0.13.3 but it should work with both terraform 12 and 13.
2. The S3 module is under folder aws-s3.
3. The source module should support most S3 common configurations.
4. The example terraform file will create 3 buckets, each bucket should have different configurations.
5. Change the backend when you trying to apply the change.
6. Update the region if not intent to use the default region along with other variables.

# Example terraform output
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

daily_bucket_domain_name = working-time-rates-daily.s3.amazonaws.com
daily_bucket_id = working-time-rates-daily
hourly_bucket_domain_name = working-time-rates-hourly.s3.amazonaws.com
hourly_bucket_id = working-time-rates-hourly
weekly_bucket_domain_name = working-time-rates-weekly.s3.amazonaws.com
weekly_bucket_id = working-time-rates-weekly
