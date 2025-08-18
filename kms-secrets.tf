# Description: This file sets up KMS for encryption and
# Secrets Manager for storing sensitive data like the
# database credentials.
# -------------------------------------------------------------

# Create a dedicated KMS key for encrypting secrets
resource "aws_kms_key" "secrets_key" {
  # ... other configuration ...
  depends_on = [
    aws_iam_role.web_tier_role,
    aws_iam_role.app_tier_role,
  ]
  description             = "KMS key for encrypting secrets"
  # amazonq-ignore-next-line
  deletion_window_in_days = 10
  # Ensure only authorized roles can use this key
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "kms:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = [aws_iam_role.web_tier_role.arn, aws_iam_role.app_tier_role.arn]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
    ]
  })
}

# Create an RDS MySQL database secret
resource "aws_secretsmanager_secret" "db_credentials" {
  name                     = "db-credentials"
  description              = "RDS MySQL database credentials"
  kms_key_id               = aws_kms_key.secrets_key.arn
}

# Store the actual secret value. 
# This should be a securely generated value, not hardcoded.
resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

resource "random_password" "db_password" {
  length  = 16
  special = true
  keepers = {
    version = "1"
  }
}

# Use data sources to get the current AWS account ID
data "aws_caller_identity" "current" {}