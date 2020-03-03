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

terraform {
  backend "s3" {
    bucket  = "130541009828-build-state-bucket-test"
    key     = "terraform.Antonio.000base.tfstate"
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

locals {

  tags = {
    Environment     = var.environment
    ServiceProvider = "Antonio"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway = true
  tags               = local.tags
  # tags = {
  #   Terraform   = "true"
  #   Environment = "dev"
  # }
}
