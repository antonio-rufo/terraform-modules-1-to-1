provider "aws" {
  access_key          = var.AWS_ACCESS_KEY
  secret_key          = var.AWS_SECRET_KEY
  region              = var.AWS_REGION
  version             = "~> 2.17"
  allowed_account_ids = ["${var.aws_account_id}"]
}

provider "random" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

provider "tls" {
  version = "~> 2.1.1"
}

provider "null" {
  version = "~> 2.0"
}

terraform {
  backend "s3" {
    bucket  = "130541009828-build-state-bucket-test"
    key     = "terraform.Antonio.200compute.tfstate"
    region  = "ap-southeast-2"
    encrypt = "true"
  }
}

# data "aws_availability_zone" "current" {}

data "terraform_remote_state" "main_state" {
  backend = "local"
  config = {
    path = "../../_main/terraform.tfstate"
  }
}

data "terraform_remote_state" "tf_000base" {
  backend = "s3"
  config = {
    bucket = "130541009828-build-state-bucket-test"
    key    = "terraform.Antonio.000base.tfstate"
    region = "ap-southeast-2"
  }
}

locals {

  tags = {
    Environment     = var.environment
    ServiceProvider = "Antonio"
  }
}

module "ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"

  vpc_id      = data.terraform_remote_state.tf_000base.outputs.base_network_vpc_id
  name        = "EC2-SG"
  description = "security group for ec2 instances"

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "http ports"
      cidr_blocks = "10.0.0.0/16"
    },
    # {
    #   from_port   = 22
    #   to_port     = 22
    #   protocol    = "tcp"
    #   description = "SSH ports"
    #   cidr_blocks = "10.0.0.0/16"
    # },
  ]
  tags = local.tags
  # tags = {
  #   Name = "EC2-SG"
  # }
}

module "rds_sg" {
  source = "terraform-aws-modules/security-group/aws"

  vpc_id      = data.terraform_remote_state.tf_000base.outputs.base_network_vpc_id
  name        = "RDS-SG"
  description = "security group for RDS DB"

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "RDS ports"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = local.tags
  # tags = {
  #   Name = "RDS-SG"
  # }
}

module "elb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  vpc_id      = data.terraform_remote_state.tf_000base.outputs.base_network_vpc_id
  name        = "ELB-SG"
  description = "security group for load balancer"

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = local.tags
  # tags = {
  #   Name = "ELB-SG"
  # }
}

# module "elb_http" {
#   source  = "terraform-aws-modules/elb/aws"
#   version = "~> 2.0"
#
#   name = "elb-example"
#
#   subnets         = data.terraform_remote_state.tf_000base.outputs.base_network_public_subnets
#   security_groups = ["${module.elb_sg.this_security_group_id}"]
#   internal        = false
#
#   listener = [
#     {
#       instance_port     = "80"
#       instance_protocol = "HTTP"
#       lb_port           = "80"
#       lb_protocol       = "HTTP"
#     },
#   ]
#
#   health_check = {
#     target              = "HTTP:80/healthy.html"
#     interval            = 30
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 5
#   }
#   cross_zone_load_balancing   = true
#   connection_draining         = true
#   connection_draining_timeout = 400
#
#   tags = {
#     Owner       = "user"
#     Environment = "dev"
#   }
# }

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = "service"

  # Launch configuration
  lc_name         = "example-lc"
  image_id        = "ami-0f767afb799f45102"
  instance_type   = "t2.micro"
  security_groups = ["${module.ec2_sg.this_security_group_id}"]

  user_data = file(var.ASG_USER_DATA_WPSTP)
  key_name  = aws_key_pair.mykeypair.key_name

  # Auto scaling group
  asg_name                  = "example-asg"
  vpc_zone_identifier       = data.terraform_remote_state.tf_000base.outputs.base_network_public_subnets
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true

  # load_balancers    = ["${module.alb.this_lb_dns_name}"]
  # target_group_arns = ["${module.alb.target_group_arns[0]}"]

  tags = [
    {
      key                 = "Environment"
      value               = "Staging"
      propagate_at_launch = true
    },
    {
      key                 = "ServiceProvider"
      value               = "Antonio"
      propagate_at_launch = true
    },
  ]
}

resource "aws_key_pair" "mykeypair" {
  key_name   = "mykey"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
  lifecycle {
    ignore_changes = [public_key]
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "my-alb"

  load_balancer_type = "application"

  vpc_id          = data.terraform_remote_state.tf_000base.outputs.base_network_vpc_id
  subnets         = data.terraform_remote_state.tf_000base.outputs.base_network_public_subnets
  security_groups = ["${module.elb_sg.this_security_group_id}"]

  # access_logs = {
  #   bucket = "my-alb-logs"
  # }

  target_groups = [
    {
      name_prefix      = "test"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  # https_listeners = [
  #   {
  #     port               = 443
  #     protocol           = "HTTPS"
  #     certificate_arn    = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
  #     target_group_index = 0
  #   }
  # ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "Test"
  }
}

# ### ADDED ON STUFF
#
# module "redirect_sg" {
#   source = "terraform-aws-modules/security-group/aws"
#
#   vpc_id      = module.vpc.vpc_id
#   name        = "Redirect-SG"
#   description = "security group for ec2 instances for redirection"
#
#   egress_cidr_blocks = ["0.0.0.0/0"]
#   egress_with_cidr_blocks = [
#     {
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       description = "All"
#       cidr_blocks = "0.0.0.0/0"
#     },
#   ]
#
#   ingress_cidr_blocks = ["0.0.0.0/0"]
#   ingress_with_cidr_blocks = [
#     {
#       from_port   = 80
#       to_port     = 80
#       protocol    = "tcp"
#       description = "http ports"
#       cidr_blocks = "0.0.0.0/0"
#     },
#     {
#       from_port   = 443
#       to_port     = 443
#       protocol    = "tcp"
#       description = "HTTPS Only"
#       cidr_blocks = "0.0.0.0/0"
#     },
#   ]
#   tags = {
#     Name = "Redirect-SG"
#   }
# }
#
# module "ec2_cluster" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "~> 2.0"
#
#   name           = "my-cluster"
#   instance_count = 1
#
#   ami                    = "ami-0f767afb799f45102"
#   instance_type          = "t2.micro"
#   vpc_security_group_ids = ["${module.redirect_sg.this_security_group_id}"]
#   subnet_ids             = module.vpc.public_subnets
#
#   user_data = file(var.ASG_USER_DATA_WPSTP)
#   key_name  = aws_key_pair.mykeypair.key_name
#
#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }
#
# resource "aws_eip" "this" {
#   vpc      = true
#   instance = module.ec2_cluster.id[0]
#
#   tags = {
#     Name = "Redirect Elastic IP"
#   }
# }
