# Description: This file implements CloudTrail and WAF.
# -------------------------------------------------------------

# -------------------------------------------------------------
# CloudTrail and CloudWatch Resources
# -------------------------------------------------------------

# CloudTrail S3 Bucket for log storage
resource "aws_s3_bucket" "cloudtrail_logs" {
  # The bucket name must be globally unique across all of AWS
  # We use the account ID to ensure uniqueness
  bucket = "cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
}

# S3 Bucket Public Access Block
# This is a best practice to prevent the bucket from being publicly accessible.
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy for CloudTrail logs
resource "aws_s3_bucket_policy" "cloudtrail_logs_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  # The policy allows CloudTrail to write logs to the S3 bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
    ]
  })
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "cloudtrail_logs_versioning" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_s3_bucket_sse" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      # Use the ARN of the KMS key data source
      kms_master_key_id = aws_kms_key.secrets_key.arn
    }
  }
}

# CloudTrail CloudWatch Log Group
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "CloudTrail-Log-Group"
  retention_in_days = 90
}

# IAM Role for CloudTrail to publish logs to CloudWatch
resource "aws_iam_role" "cloudtrail_role" {
  name = "cloudtrail-cloudwatch-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
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
        Effect = "Allow"
        # ADDED `logs:DescribeLogGroups` to fix the validation error
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
      },
    ]
  })
}

# AWS CloudTrail Trail
resource "aws_cloudtrail" "trail" {
  depends_on = [
    aws_cloudwatch_log_group.cloudtrail_log_group,
    aws_iam_role.cloudtrail_role,
    aws_iam_role_policy.cloudtrail_policy
  ]
  name                          = "management-events-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_role.arn
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
    # Use a unique name for this rule
    name       = "CommonRuleSet"
    priority   = 1
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    override_action {
      none {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetrics" # Must be unique
      sampled_requests_enabled   = true
    }
  }

  # Rule to protect against known bad inputs and scanners
  rule {
    # Use a unique name for this rule
    name       = "KnownBadInputs"
    priority   = 2
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    override_action {
      none {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsMetrics" # Must be unique
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
