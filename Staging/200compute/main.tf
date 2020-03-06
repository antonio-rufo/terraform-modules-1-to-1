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
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = {
    Name = "EC2-SG"
  }
}

# resource "aws_security_group" "fargate_task" {
#   name_prefix = "FargateTask-"
#   description = "Access to Fargate task(s)"
#   vpc_id      = data.terraform_remote_state.tf_000base.outputs.base_network_vpc_id
#
#   tags = merge(
#     local.tags,
#     map(
#       "Name", "FargateTask"
#     )
#   )
#
#   lifecycle {
#     create_before_destroy = true
#   }
# }
