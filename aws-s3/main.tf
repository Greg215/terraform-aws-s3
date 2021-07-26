#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  S3 and policy
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
resource "aws_s3_bucket" "default" {
  bucket        = var.bucket_name
  acl           = try(length(var.grants), 0) == 0 ? var.acl : null
  region        = var.region
  force_destroy = var.force_destroy
  policy        = var.policy

  tags = {
    owner      = "greg215"
    managed_by = "terraform"
  }

  versioning {
    enabled = var.versioning_enabled
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      enabled                                = lifecycle_rule.value.enabled
      prefix                                 = lifecycle_rule.value.prefix
      tags                                   = lifecycle_rule.value.tags
      abort_incomplete_multipart_upload_days = lifecycle_rule.value.abort_incomplete_multipart_upload_days

      noncurrent_version_expiration {
        days = lifecycle_rule.value.noncurrent_version_expiration_days
      }

      dynamic "noncurrent_version_transition" {
        for_each = lifecycle_rule.value.enable_glacier_transition ? [1] : []

        content {
          days          = lifecycle_rule.value.noncurrent_version_glacier_transition_days
          storage_class = "GLACIER"
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = lifecycle_rule.value.enable_deeparchive_transition ? [1] : []

        content {
          days          = lifecycle_rule.value.noncurrent_version_deeparchive_transition_days
          storage_class = "DEEP_ARCHIVE"
        }
      }

      dynamic "transition" {
        for_each = lifecycle_rule.value.enable_glacier_transition ? [1] : []

        content {
          days          = lifecycle_rule.value.glacier_transition_days
          storage_class = "GLACIER"
        }
      }

      dynamic "transition" {
        for_each = lifecycle_rule.value.enable_deeparchive_transition ? [1] : []

        content {
          days          = lifecycle_rule.value.deeparchive_transition_days
          storage_class = "DEEP_ARCHIVE"
        }
      }

      dynamic "transition" {
        for_each = lifecycle_rule.value.enable_standard_ia_transition ? [1] : []

        content {
          days          = lifecycle_rule.value.standard_transition_days
          storage_class = "STANDARD_IA"
        }
      }

      dynamic "expiration" {
        for_each = lifecycle_rule.value.enable_current_object_expiration ? [1] : []

        content {
          days = lifecycle_rule.value.expiration_days
        }
      }
    }
  }

  dynamic "logging" {
    for_each = var.logging == null ? [] : [1]
    content {
      target_bucket = var.logging["bucket_name"]
      target_prefix = var.logging["prefix"]
    }
  }

  # https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html
  # https://www.terraform.io/docs/providers/aws/r/s3_bucket.html#enable-default-server-side-encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.kms_master_key_arn
      }
    }
  }

  dynamic "website" {
    for_each = var.website_inputs == null ? [] : var.website_inputs
    content {
      index_document           = website.value.index_document
      error_document           = website.value.error_document
      redirect_all_requests_to = website.value.redirect_all_requests_to
      routing_rules            = website.value.routing_rules
    }
  }

  dynamic "cors_rule" {
    for_each = var.cors_rule_inputs == null ? [] : var.cors_rule_inputs

    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }

  dynamic "grant" {
    for_each = try(length(var.grants), 0) == 0 || try(length(var.acl), 0) > 0 ? [] : var.grants

    content {
      id          = grant.value.id
      type        = grant.value.type
      permissions = grant.value.permissions
      uri         = grant.value.uri
    }
  }

  dynamic "replication_configuration" {
    for_each = var.s3_replication_enabled ? [1] : []

    content {
      role = aws_iam_role.replication[0].arn

      dynamic "rules" {
        for_each = var.s3_replication_rules == null ? [] : var.s3_replication_rules

        content {
          id       = rules.value.id
          priority = try(rules.value.priority, 0)
          # `prefix` at this level is a V1 feature, replaced in V2 with the filter block.
          # `prefix` conflicts with `filter`, and for multiple destinations, a filter block
          # is required even if it empty, so we always implement `prefix` as a filter.
          # OBSOLETE: prefix   = try(rules.value.prefix, null)
          status = try(rules.value.status, null)

          destination {
            # Prefer newer system of specifying bucket in rule, but maintain backward compatibility with
            # s3_replica_bucket_arn to specify single destination for all rules
            bucket             = try(length(rules.value.destination_bucket), 0) > 0 ? rules.value.destination_bucket : var.s3_replica_bucket_arn
            storage_class      = try(rules.value.destination.storage_class, "STANDARD")
            replica_kms_key_id = try(rules.value.destination.replica_kms_key_id, null)
            account_id         = try(rules.value.destination.account_id, null)

            dynamic "access_control_translation" {
              for_each = try(rules.value.destination.access_control_translation.owner, null) == null ? [] : [rules.value.destination.access_control_translation.owner]

              content {
                owner = access_control_translation.value
              }
            }
          }

          dynamic "source_selection_criteria" {
            for_each = try(rules.value.source_selection_criteria.sse_kms_encrypted_objects.enabled, null) == null ? [] : [rules.value.source_selection_criteria.sse_kms_encrypted_objects.enabled]

            content {
              sse_kms_encrypted_objects {
                enabled = source_selection_criteria.value
              }
            }
          }

          # Replication to multiple destination buckets requires that priority is specified in the rules object.
          # If the corresponding rule requires no filter, an empty configuration block filter {} must be specified.
          # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
          dynamic "filter" {
            for_each = try(rules.value.filter, null) == null ? [{ prefix = null, tags = {} }] : [rules.value.filter]

            content {
              prefix = try(filter.value.prefix, try(rules.value.prefix, null))
              tags   = try(filter.value.tags, {})
            }
          }
        }
      }
    }
  }

  dynamic "object_lock_configuration" {
    for_each = var.object_lock_configuration != null ? [1] : []
    content {
      object_lock_enabled = "Enabled"
      rule {
        default_retention {
          mode  = var.object_lock_configuration.mode
          days  = var.object_lock_configuration.days
          years = var.object_lock_configuration.years
        }
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.default.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}