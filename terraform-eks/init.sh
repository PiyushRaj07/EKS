#!/bin/bash

# Set the AWS credentials profile
export AWS_PROFILE="piyushraj"

# Set the AWS region
export AWS_DEFAULT_REGION="us-east-1"


export TF_CLI_ARGS_init="-backend-config=bucket=piyushassignmenttestbucket \
-backend-config=key=eks-us-east-1-prod-app-demo-terraform.tfstate \
-backend-config=region=us-east-1 \
-backend-config=dynamodb_table=terraform-state-lock-dynamodb" \
&& terraform init

# Run Terraform init
terraform init -var-file=terraform.tfvars
