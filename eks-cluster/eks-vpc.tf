data "aws_availability_zones" "azs" { 
	provider = aws 
}

module "my-vpc" { 
	source = "terraform-aws-modules/vpc/aws" 
	version = "5.8.1" 
	name = "my-vpc-${var.region}" 
	cidr = var.vpc_cidr_block 
	private_subnets = var.private_subnet_cidr_blocks 
	public_subnets = var.public_subnet_cidr_blocks 
	azs = data.aws_availability_zones.azs.names 
	enable_nat_gateway = true 
	single_nat_gateway = true 
	enable_dns_hostnames = true 
	tags = { 
		"kubernetes.io/cluster/${var.cluster_name}" = "shared" 
	} 
	public_subnet_tags = { 
		"kubernetes.io/cluster/${var.cluster_name}" = "shared" 
		"kubernetes.io/role/elb" = "1" 
	} 
	private_subnet_tags = { 
		"kubernetes.io/cluster/${var.cluster_name}" = "shared" 
		"kubernetes.io/role/internal-elb" = "1" 
	} 
}