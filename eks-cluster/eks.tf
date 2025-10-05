terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Change this to a newer version
    }
  }
}
provider "aws" {
  region = "us-east-1"
}
module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "~> 19.0"
  cluster_name                   = "Cluster-East"
  cluster_version                = "1.32"
  cluster_endpoint_public_access = true
  vpc_id                         = module.Cluster-East-VPC.vpc_id
  subnet_ids                     = module.Cluster-East-VPC.private_subnets
  tags = {
    environment = "development"
    application = "simple-web-app"
  }
  eks_managed_node_groups = {
    dev = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.small"]
    }
  }
}
