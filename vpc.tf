# Data source to get available AZs in current region
data "aws_availability_zones" "available" {
  state = "available"
}
# Validation to ensure at least 2 AZs are available
locals {
  az_count = length(data.aws_availability_zones.available.names)
  validation_check = local.az_count >= 2 ? true : tobool("Region must have at least 2 availability zones")
}

resource "aws_vpc" "three_tier_app_vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "VPC for three tier architecture"
  }
}
## Public Subnet- 1 ##
# amazonq-ignore-next-line
resource "aws_subnet" "public-web-subnet-1" {
  vpc_id                  = aws_vpc.three_tier_app_vpc.id
  cidr_block              = var.public_web_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet 1 for web interface"
  }
}
## Public Subnet- 2 ##
resource "aws_subnet" "public-web-subnet-2" {
  vpc_id                  = aws_vpc.three_tier_app_vpc.id
  cidr_block              = var.public_web_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet 2 for web interface"
  }
}
### Private Subnet-app 1 ###
resource "aws_subnet" "private-app-subnet-1" {
  vpc_id                  = aws_vpc.three_tier_app_vpc.id
  cidr_block              = var.private_app_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet 1 for App Tier"
  }
}
### Private Subnet-app 2 ###
resource "aws_subnet" "private-app-subnet-2" {
  vpc_id                  = aws_vpc.three_tier_app_vpc.id
  cidr_block              = var.private_app_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet 2 for App Tier"
  }
}
### Private Subnet-db 1 ###
resource "aws_subnet" "private-db-subnet-1" {
  vpc_id                  = aws_vpc.three_tier_app_vpc.id
  cidr_block              = var.private_db_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet 1 for Db Tier"
  }
}
### Private Subnet-db 2  ###
resource "aws_subnet" "private-db-subnet-2" {
  vpc_id                  = aws_vpc.three_tier_app_vpc.id
  cidr_block              = var.private_db_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet 2 for Db Tier"
  }
}