# configure aws provider
provider "aws" {
  region  = var.region
  #profile = "piyushraj"
}

# configure backend
terraform {
  backend "s3" {
    bucket         = "piyushraj-terraform"
    key            = "eks-us-east-1-prod-app-demo-terraform.tfstate"
    region         = "us-east-1"
    profile        = "piyushraj"
    dynamodb_table = "terraform-state-lock-dynamodb"
  }
}
