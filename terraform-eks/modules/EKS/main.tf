# Creating EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = "AWS-EKS"
  role_arn = var.master_arn
  vpc_config {
    subnet_ids = [var.public_subnet_az1_id, var.public_subnet_az2_id]
  }

  tags = {
    key   = var.env
    value = var.type
  }
}

# Using Data Source to get all Avalablility Zones in Region
data "aws_availability_zones" "available_zones" {}

# Fetching Ubuntu 20.04 AMI ID
data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
# cannonical account number 
  owners = ["099720109477"] 
}

output "example_output" {
  value = var.ami_owners
}

# Creating kubectl server
resource "aws_instance" "kubectl-server" {
  ami                         = data.aws_ami.amazon_linux_2.id
  key_name                    = var.key_name
  instance_type               = var.instance_size
  associate_public_ip_address = true
  subnet_id                   = var.public_subnet_az1_id
  vpc_security_group_ids      = [var.eks_security_group_id]

  tags = {
    Name = "${var.project_name}-kubectl"
    Env  = var.env
    Type = var.type
  }
}

# Creating Worker Node Group
resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "Worker-Node-Group"
  node_role_arn   = var.worker_arn
  subnet_ids      = [var.public_subnet_az1_id, var.public_subnet_az2_id]
  capacity_type   = "ON_DEMAND"
  disk_size       = 20
  instance_types  = [var.instance_size]

  remote_access {
    ec2_ssh_key               = var.key_name
    source_security_group_ids = [var.eks_security_group_id]
  }

  labels = {
    env = "Prod"
  }

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
}

resource "aws_eks_addon" "addons" {
  for_each          = { for addon in var.addons : addon.name => addon }
  cluster_name      = aws_eks_cluster.eks.id
  addon_name        = each.value.name
  addon_version     = each.value.version
  resolve_conflicts = "OVERWRITE"
}

## null resource for kubectl apply 
resource "null_resource" "controller_rancher_installation" {

  provisioner "local-exec" {
    command = <<EOT
      echo "Downloading rancher config"
      git clone git@github.com:PiyushRaj07/EKS.git
      cd EKS
      kubectl  apply -f ../spring3hibernatejava
    EOT
  }
}