variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_web_subnet_1_cidr" {
  description = "The CIDR block for the first public web subnet"
  type        = string
}

variable "public_web_subnet_2_cidr" {
  description = "The CIDR block for the second public web subnet"
  type        = string
}

variable "private_app_subnet_1_cidr" {
  description = "The CIDR block for the first private app subnet"
  type        = string
}

variable "private_app_subnet_2_cidr" {
  description = "The CIDR block for the second private app subnet"
  type        = string
}

variable "private_db_subnet_1_cidr" {
  description = "The CIDR block for the first private database subnet"
  type        = string
}

variable "private_db_subnet_2_cidr" {
  description = "The CIDR block for the second private database subnet"
  type        = string
}

variable "profile" {
  description = "The AWS CLI profile to use for authentication"
  type        = string
}

variable "ssh_locate" {
  description = "The CIDR block to allow SSH access from."
  type        = string
}
variable "db_username" {
  description = "The username for the RDS database."
  type        = string
}
variable "db_instance_class" {
  description = "The instance type for the RDS database (e.g., db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "multi_az_deployment" {
  description = "Specifies whether the database instance is a multi-AZ deployment"
  type        = bool
  default     = false
}
# --- S3 Variables ---
variable "s3_bucket_name" {
  description = "The name for the S3 bucket to store application files"
  type        = string
}
variable "notification_email" {
  description = "The email address to receive SNS notifications."
  type        = string
  sensitive   = true 
}

