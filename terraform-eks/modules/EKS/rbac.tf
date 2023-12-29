provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
  #load_config_file       = false
  username               = "piyushraj"
}

data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}


resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = var.worker_arn  # Replace with the actual ARN of the worker node IAM role
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])

    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::{{account}}:user/piyushraj"
        username = "piyushraj"
        groups   = ["system:masters"]
      },
      {
        userarn  = "arn:aws:iam::{{account}}:user/Eks-demo-user"
        username = "Eks-demo-user"
        groups   = ["system:masters"]  # Adjust the group as needed
      },
      {
        userarn  = "arn:aws:iam::{{account}}:role/tf-validate-project-codepipeline-role"
        username = "tf-project-codepipeline-role"
        groups   = ["system:masters"]  # Adjust the group as needed
      }
      # Add more users here if needed
    ])
  }

  depends_on = [aws_eks_cluster.eks]
}  

resource "kubernetes_role_binding" "configmap_reader_binding" {
  metadata {
    name      = "configmap-reader-binding"
    namespace = "kube-system"
  }

  subject {
    kind      = "Group"  # Use "Group" if you have mapped an IAM role
    name      = "arn:aws:iam::{{account}}:role/tf-validate-project-codepipeline-role"
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind      = "Role"
    name      = kubernetes_role.configmap_reader.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}


resource "kubernetes_role" "configmap_reader" {
  metadata {
    name      = "configmap-reader"
    namespace = "kube-system"
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "list", "watch"]
  }
}
