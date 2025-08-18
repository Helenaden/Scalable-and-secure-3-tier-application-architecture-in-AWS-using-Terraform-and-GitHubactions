# Description: This file enables and configures AWS GuardDuty for
# threat detection and AWS Inspector for vulnerability scanning.
# -------------------------------------------------------------

# Enable GuardDuty Detector for the account
resource "aws_guardduty_detector" "default" {
  enable = true
  tags = {
    "Project" = "Three-Tier-App"
  }
}

# Define the assessment target for Inspector. This tells Inspector
# which resources to scan. We'll use a resource group based on tags.
resource "aws_inspector_assessment_target" "web_app_target" {
  name = "web-app-vulnerability-target"
  # This reference now matches the resource block name below
  resource_group_arn = aws_inspector_resource_group.web_app_group.arn
}

# Define the resource group for the assessment target. This uses the
# 'Name' tags to find the instances to be scanned.
resource "aws_inspector_resource_group" "web_app_group" {
  tags = {
    "Name" = "Web-Tier-Instance"
  }
}
# Data source to get Inspector rule packages for current region
data "aws_inspector_rules_packages" "rules" {}

# Define the assessment template. This specifies the rules for the scan,
# in this case, the CIS benchmark.
resource "aws_inspector_assessment_template" "cis_benchmark" {
  name         = "cis-benchmark-template"
  target_arn   = aws_inspector_assessment_target.web_app_target.arn
  duration     = 3600 # The duration of the assessment run in seconds (1 hour)

  # Use dynamically fetched rule package ARNs
  rules_package_arns = data.aws_inspector_rules_packages.rules.arns

  # SNS topic to notify of new findings
  event_subscription {
    event = "FINDING_REPORTED"
    topic_arn = aws_sns_topic.inspector_findings.arn
  }
}

# Create an SNS topic for Inspector findings
resource "aws_sns_topic" "inspector_findings" {
  name = "inspector-findings-alerts"
  kms_master_key_id = aws_kms_key.secrets_key.arn
}

# Create an SNS topic for GuardDuty findings
resource "aws_sns_topic" "guardduty_findings" {
  name = "guardduty-findings-alerts"
  kms_master_key_id = aws_kms_key.secrets_key.arn
}
