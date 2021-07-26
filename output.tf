output "hourly_bucket_id" {
  value       = module.hourly.bucket_id
  description = "Bucket Name (aka ID)"
}

output "daily_bucket_id" {
  value       = module.daily.bucket_id
  description = "Bucket Name (aka ID)"
}

output "weekly_bucket_id" {
  value       = module.weekly.bucket_id
  description = "Bucket Name (aka ID)"
}

output "hourly_bucket_domain_name" {
  value       = module.hourly.bucket_domain_name
  description = "FQDN of bucket"
}

output "daily_bucket_domain_name" {
  value       = module.daily.bucket_domain_name
  description = "FQDN of bucket"
}

output "weekly_bucket_domain_name" {
  value       = module.weekly.bucket_domain_name
  description = "FQDN of bucket"
}