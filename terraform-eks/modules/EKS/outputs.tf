# EKS Cluster ID
output "aws_eks_cluster_name" {
  value = aws_eks_cluster.eks.id
}

output "eks_asg_name" {
  value = aws_eks_node_group.node-grp.resources
}
