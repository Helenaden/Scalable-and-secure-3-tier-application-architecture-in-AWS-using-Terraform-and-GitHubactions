# Description: This file defines the RDS MySQL instance for the
# database tier.
# -------------------------------------------------------------
## database subnet group ##
resource "aws_db_subnet_group" "database-subnet-group" {
  name        = "database subnets"
  subnet_ids  = [aws_subnet.private-db-subnet-1.id, 
                 aws_subnet.private-db-subnet-2.id]
  description = "Subnet group for database instance"

  tags = {
    Name = "Database Subnets"
  }
}

## database instance ##
resource "aws_db_instance" "database-instance" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  storage_type           = "gp2"
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.database-subnet-group.name
  multi_az               = var.multi_az_deployment
  vpc_security_group_ids = [aws_security_group.database_security_group.id]

  # Encrypt the database at rest using the KMS key
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.secrets_key.arn

  # The database is not publicly accessible. This is a crucial security control.
  publicly_accessible = false
  # Enable IAM database authentication
  iam_database_authentication_enabled = true

  # Use values from Secrets Manager as the final source of truth.
  # Remove the hardcoded "username" and "password" lines.
  username = jsondecode(aws_secretsmanager_secret_version.db_credentials_version.secret_string).username
  password = jsondecode(aws_secretsmanager_secret_version.db_credentials_version.secret_string).password

  # Use the final database name and snapshot setting.
  db_name  = "webappdb"
  # amazonq-ignore-next-line
  skip_final_snapshot = true

  # Enable log exports to CloudWatch
  enabled_cloudwatch_logs_exports = [
    "audit",
    "error",
    "general",
    "slowquery"
  ]
}