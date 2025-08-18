# load_balancer.tf

# Application Load Balancer
# amazonq-ignore-next-line
# amazonq-ignore-next-line
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = [aws_subnet.public-web-subnet-1.id, aws_subnet.public-web-subnet-2.id] # Assumes public subnet variables exist

  tags = {
    Name = "Web ALB"
  }
}

# Target Group to route traffic to the web tier EC2 instances
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
}

# amazonq-ignore-next-line
# Listener to forward HTTP traffic from the ALB to the target group
# amazonq-ignore-next-line
resource "aws_lb_listener" "http" {
  # amazonq-ignore-next-line
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_target_group.arn
  }
}