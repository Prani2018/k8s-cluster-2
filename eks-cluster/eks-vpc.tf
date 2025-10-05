data "aws_availability_zones" "azs" {}

module "Cluster-East-VPC" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "5.8.1"
  name                 = "Cluster-East-VPC"
  cidr                 = var.vpc_cidr_block
  private_subnets      = var.private_subnet_cidr_blocks
  public_subnets       = var.public_subnet_cidr_blocks
  azs                  = data.aws_availability_zones.azs.names
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  tags = {
    "kubernetes.io/cluster/Cluster-East" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/Cluster-East" = "shared"
    "kubernetes.io/role/elb"                  = 1
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/Cluster-East" = "shared"
    "kubernetes.io/role/internal-elb"         = 1
  }
}
