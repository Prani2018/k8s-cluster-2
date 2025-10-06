terraform { 
    backend "s3" { 
        bucket = "tf-state-files-09262025" 
        # Key will be provided via -backend-config during terraform init
        # key = "eks/cluster-state-<region>.tfstate"  
        region = "us-east-1"  # State bucket location (static) 
        encrypt = true 
    } 
}
