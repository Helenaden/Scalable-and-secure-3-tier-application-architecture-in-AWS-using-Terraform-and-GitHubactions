# security.tf

# SG Application Load Balancer
resource "aws_security_group" "alb_security_group" {
  name        = "ALB Security Group"
  description = "Allow HTTP traffic from the internet"
  vpc_id      = aws_vpc.three_tier_app_vpc.id

  # Allow inbound HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB Security Group"
  }
}

# SG Web Tier (Presentation)
resource "aws_security_group" "webserver_security_group" {
  name        = "Web Server Security Group"
  description = "Allow traffic from ALB and SSH"
  vpc_id      = aws_vpc.three_tier_app_vpc.id

  # Inbound from ALB
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
    description     = "Allow traffic from ALB"
  }

  # Inbound from SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_locate]
    description = "Allow SSH access"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web Server Security Group"
  }
}
## SG App Tier (Bastion Host) ##

resource "aws_security_group" "ssh_security_group" {
  name        = "SSH Access"
  description = "Enable ssh access on port 22"
  vpc_id      = aws_vpc.three_tier_app_vpc.id

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_locate]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh into app tier Security group"
  }
}


# SG App Tier
resource "aws_security_group" "appserver_security_group" {
  name        = "App Server Security Group"
  description = "Allow traffic from app ALB"
  vpc_id      = aws_vpc.three_tier_app_vpc.id

  # Inbound from App ALB on port 8080
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app_alb_security_group.id]
    description     = "Allow traffic from App ALB"
  }
  
  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_locate]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "App Server Security Group"
  }
}

# SG Database Tier
resource "aws_security_group" "database_security_group" {
  name        = "Database Security Group"
  description = "Allow traffic from app tier"
  vpc_id      = aws_vpc.three_tier_app_vpc.id

  # Inbound from App Servers on port 3306 (or your DB port)
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.appserver_security_group.id]
    description     = "Allow traffic from App Tier"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database Security Group"
  }
}
