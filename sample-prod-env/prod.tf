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

resource "aws_security_group" "prod_web"{
  name        = "prod_web"
  description = "Allow standard http and https ports inbound and everything outbound" 

  ingress { 
    from_port   = 80 
    to_port     = 80 
    protocol    = "tcp"
    cidr_blocks = ["x.x.x.x/32"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["x.x.x.x/32"]
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

resource "aws_instance" "prod_web"{
  count = 2
  
  ami           = "ami-065fb54436c0e2d57"
  instance_type = "t2.nano"
 
  vpc_security_group_ids = [
    aws_security_group.prod_web.id 
  ]

  tags = {
    "Terraform_managed": "true"
  }
}

resource "aws_eip" "prod_web" {
  tags = {
    "Terraform_managed": "true"
  }
  
  instance = aws_instance.prod_web.0.id
}

resource "aws_elb" "prod_web_lb" {
  name = "prod-web-lb"
  
  instances        = aws_instance.prod_web.*.id 
  subnets         = [aws_default_subnet.default_az_a.id, aws_default_subnet.default_az_b.id]
  security_groups = [aws_security_group.prod_web.id]

  listener {
    instance_port     = 80 
    instance_protocol = "http"
    lb_port           = 80 
    lb_protocol       = "http"
  }
} 

