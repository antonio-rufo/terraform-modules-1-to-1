# "aws" provider variables
variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" {}
variable "aws_account_id" {}
variable "environment" {
  default = "Staging"
}

variable "ASG_USER_DATA_WPSTP" {}

# Key variables
variable "PATH_TO_PRIVATE_KEY" {}
variable "PATH_TO_PUBLIC_KEY" {}
