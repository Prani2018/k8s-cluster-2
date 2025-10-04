terraform {
  backend "s3" {
    bucket         = "tf-state-files-09262025"
    key            = "eks/cluster-state-us-east-1.tfstate" # Separate state file per region
    region         = "us-east-1" # State bucket location (should be static)
    encrypt        = true
  }
}
