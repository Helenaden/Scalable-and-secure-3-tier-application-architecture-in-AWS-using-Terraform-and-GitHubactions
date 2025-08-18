# Description: This file implements CloudTrail and WAF.
# -------------------------------------------------------------

# CloudTrail S3 Bucket for log storage
resource "aws_s3_bucket" "cloudtrail_logs" {
  # The bucket name must be globally unique across all of AWS
  # We use the account ID to ensure uniqueness
  bucket = "cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
}

# S3 Bucket Policy for CloudTrail logs
resource "aws_s3_bucket_policy" "cloudtrail_logs_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  # The policy allows CloudTrail to write logs to the S3 bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail_logs.arn
      },
    ]
  })
}

# CloudTrail CloudWatch Log Group
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "CloudTrail-Log-Group"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.secrets_key.arn
}

# IAM Role for CloudTrail to publish logs to CloudWatch
resource "aws_iam_role" "cloudtrail_role" {
  name = "cloudtrail-cloudwatch-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      },
    ]
  })
}

# IAM Policy to allow CloudTrail to write to CloudWatch Logs
resource "aws_iam_role_policy" "cloudtrail_policy" {
  name = "cloudtrail-cloudwatch-policy"
  role = aws_iam_role.cloudtrail_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = aws_cloudwatch_log_group.cloudtrail_log_group.arn
      },
    ]
  })
}

# AWS CloudTrail Trail
resource "aws_cloudtrail" "trail" {
  name                       = "management-events-trail"
  s3_bucket_name             = aws_s3_bucket.cloudtrail_logs.id
  is_multi_region_trail      = true
  enable_log_file_validation = true # Ensures log integrity
  # Corrected ARN - removed the trailing :*
  cloud_watch_logs_group_arn = aws_cloudwatch_log_group.cloudtrail_log_group.arn
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_role.arn
}

# S3 Bucket Versioning
# This enables versioning on the bucket, which helps protect against accidental
# deletion or modification of log files.
resource "aws_s3_bucket_versioning" "cloudtrail_logs_versioning" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-Side Encryption
# This enforces server-side encryption for all objects in the bucket,
# ensuring your logs are encrypted at rest.
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_s3_bucket_sse" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.secrets_key.arn
    }
  }
}

# Web Application Firewall (WAF)
resource "aws_wafv2_web_acl" "web_acl" {
  name        = "web-tier-web-acl"
  description = "WAF for the web tier ALB"
  scope       = "REGIONAL" # Use "CLOUDFRONT" for CloudFront
  default_action {
    allow {}
  }

  # This rule is a pre-configured rule set from AWS
  # that protects against common exploits like SQLi and XSS.
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }
    action {
      # This action should be 'block' to protect against common exploits
      block {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rule to protect against Log4j2 vulnerabilities
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }
    action {
      block {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WebACL"
    sampled_requests_enabled   = true
  }
}

# Associate the WAF with the ALB
resource "aws_wafv2_web_acl_association" "web_acl_assoc" {
  resource_arn = aws_lb.web_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.web_acl.arn
}