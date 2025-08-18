# Description: This file defines the EC2 instances for the web
# and app tiers using Auto Scaling Groups for high availability.
# -------------------------------------------------------------

### Data source ###
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_key_pair" "terraform_key_3" {
  key_name   = "ec2-new3-key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_secretsmanager_secret" "ec2_private_key_new" {
  name        = "ec2-private-key-new"
  description = "EC2 private key for SSH access"
  kms_key_id  = aws_kms_key.secrets_key.arn
}

resource "aws_secretsmanager_secret_version" "ec2_private_key_version" {
  secret_id     = aws_secretsmanager_secret.ec2_private_key_new.id
  secret_string = tls_private_key.rsa.private_key_pem
}

### User Data Script for Web Server ###
data "template_file" "web_user_data" {
  template = file("${path.module}/user_data/web_user_data.sh")
}

### User Data Script for App Server ###
data "template_file" "app_user_data" {
  template = file("${path.module}/user_data/app_user_data.sh")
}

### Launch Template for Web Tier ###
resource "aws_launch_template" "web_tier_template" {
  name_prefix     = "web-tier-"
  image_id        = data.aws_ami.amazon_linux_2.id
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.terraform_key_3.key_name
  user_data       = base64encode(data.template_file.web_user_data.rendered)

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
      encrypted   = true
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.web_profile.name
  }

  vpc_security_group_ids = [aws_security_group.webserver_security_group.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Web-Tier-Instance"
    }
  }
}

### Launch Template for App Tier ###
resource "aws_launch_template" "app_tier_template" {
  name_prefix     = "app-tier-"
  image_id        = data.aws_ami.amazon_linux_2.id
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.terraform_key_3.key_name
  user_data       = base64encode(data.template_file.app_user_data.rendered)

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
      encrypted   = true
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }

  vpc_security_group_ids = [aws_security_group.appserver_security_group.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "App-Tier-Instance"
    }
  }
}

### Auto Scaling Group for Web Tier ###
resource "aws_autoscaling_group" "web_asg" {
  name                      = "web-tier-asg"
  vpc_zone_identifier       = [aws_subnet.public-web-subnet-1.id, aws_subnet.public-web-subnet-2.id]
  desired_capacity          = 2
  max_size                  = 2
  min_size                  = 2
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.web_target_group.arn]

  launch_template {
    id      = aws_launch_template.web_tier_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Web-Tier-ASG-Instance"
    propagate_at_launch = true
  }
}

### Auto Scaling Group for App Tier ###
resource "aws_autoscaling_group" "app_asg" {
  name                      = "app-tier-asg"
  vpc_zone_identifier       = [aws_subnet.private-app-subnet-1.id, aws_subnet.private-app-subnet-2.id]
  desired_capacity          = 2
  max_size                  = 2
  min_size                  = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app_tier_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "App-Tier-ASG-Instance"
    propagate_at_launch = true
  }
}

# Instance profiles to attach the IAM roles to the EC2 instances
resource "aws_iam_instance_profile" "web_profile" {
  name = "web-tier-profile"
  role = aws_iam_role.web_tier_role.name
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "app-tier-profile"
  role = aws_iam_role.app_tier_role.name
}