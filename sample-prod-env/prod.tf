provider "aws" {
  profile = "default"
  region = "us-east-1"
}

resource "aws_s3_bucket" "prod_tf_course" {
  bucket = "tf-course-20200430"
  acl = "private" 
}
  
resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az_a" {
  availability_zone = "us-east-1a"

  tags = {
    "Terraform_managed": "true"
  }
}

resource "aws_default_subnet" "default_az_b" {
  availability_zone = "us-east-1b"

  tags = {
    "Terraform_managed": "true"
  }
}

resource "aws_security_group" "prod_web_instance" {
  name = "prod-web-instance"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_web_lb.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.prod_web_lb.id]
  }

  tags = {
    "Terraform_managed": "true"
  }
}

resource "aws_security_group" "prod_web_lb" {
  name = "prod-web-lb"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Terraform_managed": "true"
  }

}

resource "aws_elb" "prod_web_lb" {
  name            = "prod-web-lb"
  subnets         = [aws_default_subnet.default_az_a.id, aws_default_subnet.default_az_b.id]
  security_groups = [aws_security_group.prod_web_lb.id]
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "80"
    instance_protocol = "http"
  }
} 

resource "aws_lb_listener" "prod_web" {
  load_balancer_arn = aws_elb.prod_web_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod_web.arn
  }
}

 resource "aws_lb_target_group" "prod_web" {
   name     = "prod-web"
   port     = 80
   protocol = "HTTP"
 }

resource "aws_launch_configuration" "prod_web" {
  name_prefix     = "prod-web-aws-asg-"
  image_id        = "ami-065fb54436c0e2d57"
  instance_type   = "t2.nano"
  security_groups = [aws_security_group.prod_web_instance.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "prod_web" {
  vpc_zone_identifier = [aws_default_subnet.default_az_a.id, aws_default_subnet.default_az_b.id]
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1
  launch_configuration = aws_launch_configuration.prod_web.name 
 
  tag {
    key = "Terraform_managed"
    value = "true"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "prod_web" {
  autoscaling_group_name = aws_autoscaling_group.prod_web.id
  elb                    = aws_elb.prod_web_lb.id
}
