# -------------------------------------------------------------
# AWS GuardDuty + AWS Inspector v2 setup with SNS notifications
# -------------------------------------------------------------

# Enable GuardDuty Detector
resource "aws_guardduty_detector" "default" {
  enable = true
  tags = {
    Project = "Three-Tier-App"
  }
}

# Create SNS topic for GuardDuty findings
resource "aws_sns_topic" "guardduty_findings" {
  name             = "guardduty-findings-alerts"
  kms_master_key_id = aws_kms_key.secrets_key.arn
}

# Subscribe your email to GuardDuty findings
resource "aws_sns_topic_subscription" "gd_email" {
  topic_arn = aws_sns_topic.guardduty_findings.arn
  protocol  = "email"
  endpoint  = var.notification_email # Use the variable for email
}
# Create an EventBridge rule for GuardDuty findings
resource "aws_cloudwatch_event_rule" "guardduty_findings_rule" {
  name        = "guardduty-findings-rule"
  description = "Capture GuardDuty findings and send to SNS"
  event_pattern = jsonencode({
    "source": ["aws.guardduty"],
    "detail-type": ["GuardDuty Finding"]
  })
}

# Target: Send GuardDuty findings to the SNS topic
resource "aws_cloudwatch_event_target" "guardduty_to_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings_rule.name
  arn       = aws_sns_topic.guardduty_findings.arn
}

# Permission for EventBridge to publish to the GuardDuty SNS topic
resource "aws_sns_topic_policy" "guardduty_policy" {
  arn    = aws_sns_topic.guardduty_findings.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.guardduty_findings.arn
      }
    ]
  })
}

# -------------------------------------------------------------
# AWS Inspector v2 (automatic scanning of EC2, ECR, Lambda)
# -------------------------------------------------------------

# Enable Inspector v2
resource "aws_inspector2_enabler" "enable" {
  account_ids = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2", "ECR", "LAMBDA"]
}

# Create SNS topic for Inspector findings
resource "aws_sns_topic" "inspector_findings" {
  name             = "inspector-findings-alerts"
  kms_master_key_id = aws_kms_key.secrets_key.arn
}

# Subscribe your email to Inspector findings
resource "aws_sns_topic_subscription" "inspector_email" {
  topic_arn = aws_sns_topic.inspector_findings.arn
  protocol  = "email"
  endpoint  = "dennishelen212@gmail.com"
}

# Create EventBridge rule for Inspector findings
resource "aws_cloudwatch_event_rule" "inspector_findings_rule" {
  name        = "inspector-findings-rule"
  description = "Capture Inspector v2 findings and send to SNS"
  event_pattern = jsonencode({
    "source" : ["aws.inspector2"],
    "detail-type" : ["Inspector2 Finding"]
  })
}

# Target: Send Inspector findings to SNS
resource "aws_cloudwatch_event_target" "inspector_to_sns" {
  rule      = aws_cloudwatch_event_rule.inspector_findings_rule.name
  arn       = aws_sns_topic.inspector_findings.arn
}

# Permission for EventBridge to publish to SNS
resource "aws_sns_topic_policy" "inspector_policy" {
  arn    = aws_sns_topic.inspector_findings.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.inspector_findings.arn
      }
    ]
  })
}