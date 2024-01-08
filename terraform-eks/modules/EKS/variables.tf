# Environment
variable "env" {
  type = string
}

# Type
variable "type" {
  type = string
}

# Stack name
variable "project_name" {
  type = string
}

# Public subnet AZ1
variable "public_subnet_az1_id" {
  type = string
}

# Public subnet AZ2
variable "public_subnet_az2_id" {
  type = string
}

# private subnet AZ1
variable "private_subnet_az1_id" {
  type = string
}

# private subnet AZ2
variable "private_subnet_az2_id" {
  type = string
}
# private  subnet AZ1
variable "private_subnet_az3_id" {
  type = string
}

# private subnet AZ2
variable "private_subnet_az4_id" {
  type = string
}

# Security Group 
variable "eks_security_group_id" {
  type = string
}

# Master ARN
variable "master_arn" {
  type = string
}

# Worker ARN
variable "worker_arn" {
  type = string
}

# Key name
variable "key_name" {
  type = string
}

# Worker Node & Kubectl instance size
variable "instance_size" {
  type = string
}

variable "ami_owners" {
  type    = list(string)
  default = ["amazon"]
}

variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))

  default = [
    {
      name    = "kube-proxy"
      version = "v1.28.2-eksbuild.2"
    },
    {
      name    = "vpc-cni"
      version = "v1.15.4-eksbuild.1"
    },
    {
      name    = "coredns"
      version = "v1.10.1-eksbuild.6"
    },
    {
      name    = "aws-ebs-csi-driver"
      version = "v1.25.0-eksbuild.1"
    },
    {
      name = "eks-pod-identity-agent"
      version = "v1.0.0-eksbuild.1"
    }
  ]
}