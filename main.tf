terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

resource "aws_security_group" "my-lb-sg" {
  name = "myAlbSg"
}

locals {

  protocol          = "tcp"
  cidr              = "154.72.162.199/32"
  security_group_id = aws_security_group.my-lb-sg.id
}

resource "aws_security_group_rule" "my-ib-http" {
  type              = "ingress"
  protocol          = "tcp"
  security_group_id = aws_security_group.my-lb-sg.id
  from_port         = 80
  cidr_blocks       = [local.cidr]
  to_port           = 80
}
# ASG sec. group
resource "aws_security_group" "my-asg-sg" {
  name = "my-asg-sg"
}

resource "aws_security_group_rule" "my-asg-http" {
  type              = "ingress"
  protocol          = local.protocol
  security_group_id = aws_security_group.my-asg-sg.id
  from_port         = 80
  cidr_blocks       = [local.cidr]
  to_port           = 80
  
}


resource "aws_launch_template" "my-lt-tf" {
  instance_type        = "t3.micro"
  image_id             = "ami-05e971bfc80cd7e58"
  key_name             = aws_key_pair.ma_cle.key_name
  user_data            = filebase64("./script.sh")
  ebs_optimized        = true
  security_group_names = [aws_security_group.my-asg-sg.name]
}



resource "aws_key_pair" "ma_cle" {
  key_name   = "macabo"
  public_key = file("./ssh-key.pub")
}


resource "aws_autoscaling_group" "exo2-asg" {
  min_size = 1
  max_size = 2
  
  name     = "my-asg-tf"
  mixed_instances_policy {

    launch_template {
    
      launch_template_specification {
        launch_template_id = aws_launch_template.my-lt-tf.id
        
      }
    }
  }
  availability_zones = [ "eu-west-3c", "eu-west-3a" ]
  
}


resource "aws_lb" "my-lb-tf" {
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my-lb-sg.id]
  ip_address_type    = "ipv4"
  internal           = false
  subnet_mapping {
    subnet_id = "subnet-07db0b5afa19fdd44"
  }
    subnet_mapping {
    subnet_id = "subnet-012b6c19cdf8d0b3f"
  }
}

output "mon_dns" {
  value = aws_lb.my-lb-tf.dns_name
}