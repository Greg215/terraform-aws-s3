variable "region" {
  type        = string
  default     = "ap-southeast-1"
  description = "If specified, the AWS region this bucket should reside in. Otherwise, the region used by the callee"
}

variable "bucket_name_hourly" {
  type        = string
  description = "The name of the bucket to be created."
  default     = "working-time-rates-hourly"
}

variable "bucket_name_daily" {
  type        = string
  description = "The name of the bucket to be created."
  default     = "working-time-rates-daily"
}

variable "bucket_name_weekly" {
  type        = string
  description = "The name of the bucket to be created."
  default     = "working-time-rates-weekly"
}