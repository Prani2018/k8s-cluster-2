variable "vpc_cidr_block" { 
	description = "CIDR block for the VPC" 
	type = string 
} 
variable "private_subnet_cidr_blocks" { 
	description = "CIDR blocks for private subnets" 
	type = list(string) 
} 
variable "public_subnet_cidr_blocks" { 
	description = "CIDR blocks for public subnets" 
	type = list(string) 
} 
variable "cluster_name" { 
	description = "Name of the EKS cluster" 
	type = string 
	default = "eks-cluster" 
} 
variable "region" { 
	description = "AWS region for the cluster" 
	type = string 
	default = "us-east-1" 
}