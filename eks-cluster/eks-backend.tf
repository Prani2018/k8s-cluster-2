terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "eks/cluster-state-${var.aws_region}.tfstate" # Separate state file per region
    region         = "us-east-1" # State bucket location (should be static)
    encrypt        = true
  }
}
