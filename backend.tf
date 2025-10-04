terraform {
  # Configuring Terraform backend to store state file in an S3 bucket
  backend "s3" {
    # Specify the name of the S3 bucket to store the state file
    bucket = "tf-state-files-09262025"
    # Specify the AWS region where the bucket is located
    region = "us-east-1"
    # Specify the path within the bucket to store the state file
    key = "k8s-cluster/terraform.tfstate"
  }
}
