variable "vpc_cidr_block" {}
variable "private_subnet_cidr_blocks" {}
variable "public_subnet_cidr_blocks" {}
variable "aws_region" {
  description = "The AWS region to deploy the resources into"
  type        = string
}

variable "cluster_name" {
  description = "The unique name for the EKS cluster and related resources"
  type        = string
}
