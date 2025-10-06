terraform { 
	required_providers { 
		aws = { 
		source = "hashicorp/aws" 
		version = "~> 5.0" 
		} 
	} 
}

provider "aws" { 
	region = var.region 
}

module "eks" { 
	source = "terraform-aws-modules/eks/aws" 
	version = "~> 19.0" 
	cluster_name = var.cluster_name 
	cluster_version = "1.32" 
	cluster_endpoint_public_access = true 
	vpc_id = module.my-vpc.vpc_id 
	subnet_ids = module.my-vpc.private_subnets 
	tags = { 
		environment = "development" 
		application = "myapp" 
	} 
	eks_managed_node_groups = { 
		dev = { 
			min_size = 1 
			max_size = 3 
			desired_size = 1 
			instance_types = ["t3.small"] 
		} 
	} 
}
