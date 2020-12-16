resource "aws_iam_role" "iam_role_s3_full_access" {
  name = "iam_role_s3_full_access"

 assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "ec2-read-only-policy-attachment" {
    role = aws_iam_role.iam_role_s3_full_access.id
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_instance_profile" "iam_role_s3_instance_profile_s3" {
  name  = "iam_role_s3_instance_profile_s3"
  role = aws_iam_role.iam_role_s3_full_access.id
}

resource "aws_launch_configuration" "asglc_01" {
  image_id        = var.instance_ami
  instance_type   = var.instance_type
  security_groups = var.security_groups_for_ec2
  iam_instance_profile = "iam_role_s3_instance_profile_s3"
  //iam_instance_profile = "iam_role_s3_instance_profile_s3"
  key_name = var.key_pair_for_ec2 //aws_key_pair.ec2key.key_name
  //data.template_file.user_data.rendered
  //aws s3 sync --delete s3://s3-wp-code-ts /var/www/html
 user_data = <<-EOF
#!/bin/bash
yum update -y

EOF
  lifecycle {
  create_before_destroy = true
  }
  
}

resource "aws_autoscaling_group" "asg_01" {
  depends_on = [aws_launch_configuration.asglc_01, aws_lb_target_group.alb_tg_01]
  launch_configuration = aws_launch_configuration.asglc_01.id // aws_launch_configuration.tslc01.name
  target_group_arns =[aws_lb_target_group.alb_tg_01.arn]

  //availability_zones = ["us-west-2a"]
  vpc_zone_identifier = var.asg_subnets_ids_list //[aws_subnet.subnet_public_1.id, aws_subnet.subnet_public_2.id]
  min_size = var.min_size
  max_size = var.max_size
  //target_group_arns = var.target_group_arns
  health_check_grace_period = var.health_check_grace_period 
    
  tag {
    key                 = "Name"
    value               = "${var.prefix}-${terraform.workspace}-asg_01"
        propagate_at_launch = true
  }

}

resource "aws_lb" "alb_01" {
  name               = var.load_balancer_name
  load_balancer_type = var.load_balancer_type
  subnets            = var.load_balancer_subnets
  security_groups    = var.load_balancer_security_groups
   tags = {
    Environment = var.environment_tag
    Name = "${var.prefix}-${terraform.workspace}-alb01"
  }
}


resource "aws_lb_listener" "alb_listener_http" {
  depends_on = [aws_lb.alb_01]
  load_balancer_arn = aws_lb.alb_01.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = var.listener_content_type
      message_body = var.listener_message_body
      status_code  = var.listener_status_code
    }
  }
}

resource "aws_lb_target_group" "alb_tg_01" {
  depends_on = [aws_lb_listener.alb_listener_http]
  name     = "albtg-rn"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
   tags = {
    Environment = var.environment_tag
    Name = "${var.prefix}-${terraform.workspace}-albtg01"
  }
}
resource "aws_lb_target_group" "alb_tg_02" {
  depends_on = [aws_lb_listener.alb_listener_http]
  name     = "albtg-wn"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
   tags = {
    Environment = var.environment_tag
    Name = "${var.prefix}-${terraform.workspace}-albtg02"
  }
}

resource "aws_lb_listener_rule" "alb_lr_01" {
  depends_on = [
    aws_lb_listener.alb_listener_http,
    aws_lb_target_group.alb_tg_01
    ]
  listener_arn = aws_lb_listener.alb_listener_http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg_01.arn
  }
 
  condition {
      path_pattern {
      values = ["/index.html*", "/"]
    }
    
 }
  

}
resource "aws_lb_listener_rule" "alb_lr_02" {
  depends_on = [
    aws_lb_listener.alb_listener_http,
    aws_lb_target_group.alb_tg_02
    ]
  listener_arn = aws_lb_listener.alb_listener_http.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg_02.arn
  }
 
  condition {
      path_pattern {
      values = ["/wp-admin*"]
    }
    
 }

}
/*
resource "aws_lb_target_group_attachment" "albtg_attachment" {
  target_group_arn = var.target_group_arn
  target_id        = var.target_id
  port             = var.port
}
*/