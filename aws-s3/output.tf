output "bucket_domain_name" {
  value       = aws_s3_bucket.default.bucket_domain_name
  description = "FQDN of bucket"
}

output "bucket_regional_domain_name" {
  value       = aws_s3_bucket.default.bucket_regional_domain_name
  description = "The bucket region-specific domain name"
}

output "bucket_id" {
  value       = aws_s3_bucket.default.id
  description = "Bucket Name (aka ID)"
}

output "bucket_arn" {
  value       = aws_s3_bucket.default.arn
  description = "Bucket ARN"
}

output "bucket_region" {
  value       = aws_s3_bucket.default.region
  description = "Bucket region"
}