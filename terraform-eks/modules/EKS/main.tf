# Creating EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = "AWS-EKS"
  role_arn = var.master_arn
  vpc_config {
    subnet_ids = [var.private_subnet_az4_id, var.private_subnet_az3_id, var.private_subnet_az2_id, var.private_subnet_az1_id  ]
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
  ami                         = "ami-0df88a6d3d96762e8"
  #"ami-079db87dc4c10ac91"
  #"data.aws_ami.amazon_linux_2.id
  key_name                    = var.key_name
  instance_type               = var.instance_size
  associate_public_ip_address = true
  subnet_id                   = var.private_subnet_az1_id
  vpc_security_group_ids      = [var.eks_security_group_id]

  tags = {
    Name = "${var.project_name}-kubectl"
    Env  = var.env
    Type = var.type
  }
}


resource "aws_eks_addon" "addons" {
  for_each          = { for addon in var.addons : addon.name => addon }
  cluster_name      = aws_eks_cluster.eks.id
  addon_name        = each.value.name
  addon_version     = each.value.version
  resolve_conflicts = "OVERWRITE"
}


###----------------###
# Create a launch template for your worker nodes
resource "aws_launch_template" "eks_node_group" {
  name_prefix   = "eks-node-group-template-"
  image_id      = "ami-0df88a6d3d96762e8"
  instance_type = var.instance_size
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
      volume_type = "gp2"
    }
  }
  user_data = base64encode(<<-EOF
    #!/bin/bash
    cat > /tmp/cwagent-config.json <<EOL
    {
      "agent": {
        "debug": true,
        "metrics_collection_interval": 60,
        "logfile": "/var/log/amazon-cloudwatch-agent/amazon-cloudwatch-agent.log"
      },
      "metrics": {
        "namespace": "CustomNamespace",
        "aggregation_dimensions": [["AutoScalingGroupName"]],
        "metrics_collected": {
          "disk": {
            "measurement": [
              "used_percent",
              "inodes_free"
            ],
            "metrics_collection_interval": 60,
            "resources": [
              "*"
            ],
            "ignore_file_system_types": ["sysfs", "devtmpfs", "tracefs", "tmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]
          },
          "mem": {
            "measurement": [
              "mem_used_percent"
            ],
            "metrics_collection_interval": 60
          }
        }
      }
    }

    EOL
    sudo yum install -y amazon-cloudwatch-agent && 
    sudo cp -f  /tmp/cwagent-config.json /opt/aws/amazon-cloudwatch-agent/bin/config.json &&
    sudo systemctl enable amazon-cloudwatch-agent &&
    sudo systemctl start amazon-cloudwatch-agent  &&
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a start
    # Bootstrap commands for EKS worker nodes
    /etc/eks/bootstrap.sh AWS-EKS
  EOF
  )
  
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "EKS-MANAGED-NODE"
    }
  }
}

# Define a custom metric for memory utilization
resource "aws_cloudwatch_metric_alarm" "high_memory_utilization" {
  alarm_name          = "HighMemoryUtilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "mem_used_percent" # Custom metric name
  statistic          = "Average"
  namespace           = "CustomNamespace" 
  period              = 300
  threshold           = 30

  dimensions = {
    AutoScalingGroupName = aws_eks_node_group.node-grp.resources[0].autoscaling_groups[0].name
  }

  alarm_description = "Trigger a scale-out if memory utilization exceeds 80%."
  alarm_actions     = [aws_autoscaling_policy.scale_out.arn]
}


resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name          = "HighCPUUtilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300  # 5 minutes
  statistic           = "Average"
  threshold           = 80   # Trigger when CPU utilization is greater than or equal to 80%

  dimensions = {
    AutoScalingGroupName = aws_eks_node_group.node-grp.resources[0].autoscaling_groups[0].name
  }

  alarm_description = "Trigger a scale-out if CPU utilization exceeds 80%."
  alarm_actions     = [aws_autoscaling_policy.scale_out.arn]  # Replace with the actual action
}


# Define an Auto Scaling policy for scaling out
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale_out_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_eks_node_group.node-grp.resources[0].autoscaling_groups[0].name
}

# Define an Auto Scaling policy for scaling in (optional but recommended)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale_in_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_eks_node_group.node-grp.resources[0].autoscaling_groups[0].name
}

# Creating Worker Node Group
resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "Worker-Node-Group"
  node_role_arn   = var.worker_arn
  subnet_ids      = [var.private_subnet_az2_id, var.private_subnet_az1_id]
  capacity_type   = "ON_DEMAND"

 # instance_types  = [var.instance_size]

  # Using local.node_labels to set labels for nodes
  scaling_config {
    min_size     = 1
    max_size     = 4
    desired_size = 2
  }


  # Attach the launch template
  launch_template {
    id      = aws_launch_template.eks_node_group.id
    version = "$Latest"
  }

  update_config {
    max_unavailable = 1
  }
}