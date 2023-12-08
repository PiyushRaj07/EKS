# Creating AWS EKS for multiple customers Cluster using Terraform Modules

Amazon Elastic Kubernetes Service (Amazon EKS) is a managed Kubernetes service provided by AWS. Through AWS EKS we can run Kubernetes without installing and operating a Kubernetes control plane or worker nodes. AWS EKS helps you provide highly available and secure clusters and automates key tasks such as patching, node provisioning, and updates.

# steps to run
1:  run ./init.sh

2:  terraform plan -var-file=terraform.tfvars

3:  terraform apply -var-file=terraform.tfvars


# steps to clean

1:  terraform destory -var-file=terraform.tfvars


## issues:

# error 1:
╷
│ Error: Failed to get existing workspaces: S3 bucket does not exist.
│ 
│ The referenced S3 bucket must have been previously created. If the S3 bucket
│ was created within the last minute, please wait for a minute or two and try
│ again.
│ 
│ Error: NoSuchBucket: The specified bucket does not exist
│ 	status code: 404, request id: 5EWKH0NFJC9PNAJV, host id: B6zF85j/iLgg7lzDShD5EGypiCSD3BxB/yxIiehjP4woOCP08lChSV+EESru3IWc044dMq0copc=

# soltn: create desired bucket and table manually

# erro 2:
Initializing the backend...
Error refreshing state: BucketRegionError: incorrect region, the bucket is not in 'us-east-2' region at endpoint '', bucket is in 'us-east-1' region
	status code: 301

# soltn: check aws profile region & provider region 