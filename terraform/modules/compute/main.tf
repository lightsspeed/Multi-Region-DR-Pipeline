# Compute Module - ALB, ASG, Launch Template

variable "region_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "ec2_sg_id" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "db_endpoint" {
  type = string
}

variable "db_password" {
  type = string
}

variable "random_suffix" {
  type = string
}

# IAM Role for EC2
resource "aws_iam_role" "ec2" {
  name = "${var.region_name}-ec2-role-${var.random_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.region_name}-ec2-profile-${var.random_suffix}"
  role = aws_iam_role.ec2.name
}

# ALB
resource "aws_lb" "app" {
  name               = "${var.region_name}-alb-${var.random_suffix}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets

  tags = {
    Name = "${var.region_name}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.region_name}-tg-${var.random_suffix}"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "${var.region_name}-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ec2_sg_id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum install python3-pip -y
              pip3 install flask mysql-connector-python
              
              cat << 'APP' > /home/ec2-user/app.py
              from flask import Flask, jsonify
              import os
              app = Flask(__name__)
              @app.route('/health')
              def health():
                  return jsonify({"status": "healthy", "region": "${var.region_name}", "target": "ready"})
              if __name__ == '__main__':
                  app.run(host='0.0.0.0', port=5000)
              APP
              
              nohup python3 /home/ec2-user/app.py > /home/ec2-user/app.log 2>&1 &
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.region_name}-app-instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                = "${var.region_name}-asg-${var.random_suffix}"
  desired_capacity    = 2
  max_size            = 6
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.app.arn]
  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.region_name}-asg-instance"
    propagate_at_launch = true
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "alb_zone_id" {
  value = aws_lb.app.zone_id
}

output "alb_arn_suffix" {
  value = aws_lb.app.arn_suffix
}

output "alb_tg_arn_suffix" {
  value = aws_lb_target_group.app.arn_suffix
}

output "asg_name" {
  value = aws_autoscaling_group.app.name
}
