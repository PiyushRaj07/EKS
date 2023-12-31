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

# VPC CIDR
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# CIDR of public subet in AZ1 
variable "public_subnet_az1_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

# CIDR of public subet in AZ2
variable "public_subnet_az2_cidr" {
  type    = string
  default = "10.0.2.0/24"
}



# CIDR of public subet in AZ1  256 
variable "private_subnet_az1_cidr" {
  type    = string
  default = "10.0.4.0/24"
}

# CIDR of public subet in AZ2
variable "private_subnet_az2_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

# CIDR of public subet in AZ1  256 
variable "private_2_subnet_az1_cidr" {
  type    = string
  default = "10.0.5.0/24"
}

# CIDR of public subet in AZ2
variable "private_2_subnet_az2_cidr" {
  type    = string
  default = "10.0.6.0/24"
}