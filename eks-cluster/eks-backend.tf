terraform { 
	backend "s3" { 
		bucket = "tf-state-files-09262025" 
		key = "eks/cluster-state-${var.region}.tfstate" 
		region = "us-east-1" # State bucket location (static) 
		encrypt = true 
	} 
}