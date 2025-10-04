variable "vpc_cidr_block" {}
variable "private_subnet_cidr_blocks" {}
variable "public_subnet_cidr_blocks" {}
variable "aws_region" {
  description = "The AWS region to deploy the resources into"
  type        = string
  default     = "us-east-1" # Set a safe default
}
