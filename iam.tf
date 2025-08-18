# Description: This file defines the IAM roles and policies for
# the Web and App tiers, following the principle of least privilege.
# -------------------------------------------------------------

# Create the IAM Role for the Web Tier
resource "aws_iam_role" "web_tier_role" {
  name = "web-tier-role"
  path = "/"

  # The trust policy that allows EC2 instances to assume this role.
  # This is a security best practice for assigning roles to EC2.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Create the IAM Role for the Application Tier
resource "aws_iam_role" "app_tier_role" {
  name = "app-tier-role"
  path = "/"

  # The trust policy that allows EC2 instances to assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Define the policy for the Web Tier.
# This policy only allows the role to retrieve a specific secret.
# This is a key part of implementing least privilege.
data "aws_iam_policy_document" "web_tier_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      # The ARN of the secret we'll create later in kms_secrets.tf
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:db-credentials*",
      # New: Permission to retrieve the EC2 private key
      aws_secretsmanager_secret.ec2_private_key.arn,
    ]
  }
}

# Attach the policy document to the Web Tier role
resource "aws_iam_role_policy" "web_tier_policy" {
  name   = "web-tier-policy"
  role   = aws_iam_role.web_tier_role.id
  policy = data.aws_iam_policy_document.web_tier_policy_doc.json
}

# Define the policy for the Application Tier.
# This policy allows access to the database credentials and
# assumes it might need to access S3 for internal services.
data "aws_iam_policy_document" "app_tier_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:db-credentials*",
      # New: Permission to retrieve the EC2 private key
      aws_secretsmanager_secret.ec2_private_key.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      # Replace with your S3 bucket ARN if you have one for the app tier.
      aws_s3_bucket.app_files.arn,
      "${aws_s3_bucket.app_files.arn}/*",
    ]
  }
}

# Attach the policy document to the App Tier role
resource "aws_iam_role_policy" "app_tier_policy" {
  name   = "app-tier-policy"
  role   = aws_iam_role.app_tier_role.id
  policy = data.aws_iam_policy_document.app_tier_policy_doc.json
}

#Add an IAM policy for the Inspector agent.
resource "aws_iam_role_policy_attachment" "inspector_agent_web_policy_attach" {
  role       = aws_iam_role.web_tier_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "inspector_agent_app_policy_attach" {
  role       = aws_iam_role.app_tier_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2RoleforSSM"
}
