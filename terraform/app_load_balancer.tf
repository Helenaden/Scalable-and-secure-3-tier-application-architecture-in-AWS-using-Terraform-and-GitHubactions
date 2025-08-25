# load_balancer.tf

# =============================================================================
# WEB TIER APPLICATION LOAD BALANCER (Internet-facing)
# =============================================================================

resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = [aws_subnet.public-web-subnet-1.id, aws_subnet.public-web-subnet-2.id]

  tags = {
    Name = "Web ALB"
  }
}

# Target Group for Web Tier
resource "aws_lb_target_group" "web_target_group" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.three_tier_app_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 5
    unhealthy_threshold = 8
  }

  tags = {
    Name = "Web Target Group"
  }
}

# Listener for Web ALB
resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_target_group.arn
  }
}

# =============================================================================
# APPLICATION TIER LOAD BALANCER (Internal)
# =============================================================================

# Security Group for App ALB
resource "aws_security_group" "app_alb_security_group" {
  name        = "App ALB Security Group"
  description = "Allow HTTP traffic from web tier"
  vpc_id      = aws_vpc.three_tier_app_vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.webserver_security_group.id]
    description     = "Allow traffic from Web Tier"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "App ALB Security Group"
  }
}

# Internal Application Load Balancer for App Tier
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_alb_security_group.id]
  subnets            = [aws_subnet.private-app-subnet-1.id, aws_subnet.private-app-subnet-2.id]

  tags = {
    Name = "App ALB Internal"
  }
}

# Target Group for App Tier
resource "aws_lb_target_group" "app_target_group" {
  name     = "app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.three_tier_app_vpc.id

  health_check {
    path                = "/"
    port                = "8080"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name = "App Target Group"
  }
}

# Listener for App ALB
resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "web_alb_dns_name" {
  description = "DNS name of the web ALB"
  value       = aws_lb.web_alb.dns_name
}

output "app_alb_dns_name" {
  description = "DNS name of the app ALB"
  value       = aws_lb.app_alb.dns_name
}