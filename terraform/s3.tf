# s3.tf
# Terraform resource block for an AWS S3 bucket.

resource "aws_s3_bucket" "app_files" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "Web-Tier-App-Files"
  }
}

resource "aws_s3_bucket_versioning" "app_files_versioning" {
  bucket = aws_s3_bucket.app_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_files_encryption" {
  bucket = aws_s3_bucket.app_files.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.secrets_key.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_files_pab" {
  bucket = aws_s3_bucket.app_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

