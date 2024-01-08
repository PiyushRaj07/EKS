provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.eks.identity.0.oidc.0.issuer
}

# IAM OIDC Provider for the EKS cluster
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926cc7f0398ea98ff4e5f5206"] # Update with the current thumbprint
  url             = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer

  depends_on = [aws_eks_cluster.eks]
}

data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

resource "kubernetes_cluster_role" "trainee_clusterrole" {
  metadata {
    name = "trainee-clusterrole"
  }

  rule {
    api_groups = [""]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "trainee_clusterrole_binding" {
  metadata {
    name = "trainee-clusterrole-binding"
  }

  subject {
    kind      = "User"
    name      = "eks-trainee"
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind     = "ClusterRole"
    name     = kubernetes_cluster_role.trainee_clusterrole.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role" "developer_clusterrole" {
  metadata {
    name = "developer-clusterrole"
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_cluster_role_binding" "developer_clusterrole_binding" {
  metadata {
    name = "developer-clusterrole-binding"
  }

  subject {
    kind      = "User"
    name      = "eks-developer"  # Replace with the actual user name
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind     = "ClusterRole"
    name     = kubernetes_cluster_role.developer_clusterrole.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
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
      },
      {
        rolearn  = "arn:aws:iam::{{ replace your acct id}}:role/tf-validate-project-codepipeline-role"  # Replace with the actual ARN of the worker node IAM role
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])

    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::{{ replace your acct id}}:user/piyushraj"
        username = "piyushraj"
        groups   = ["system:masters"]
      },
      {
        userarn  = "arn:aws:iam::{{ replace your acct id}}:user/eks-trainee"
        username = "eks-trainee"
      },
      {
        userarn  = "arn:aws:iam::{{ replace your acct id}}:user/developer"
        username = "developer"
      }
      # Add more users here if needed
    ])
  }


  depends_on = [aws_eks_cluster.eks]
}  
#
#resource "kubernetes_role_binding" "configmap_reader_binding" {
#  metadata {
#    name      = "configmap-reader-binding"
#     namespace = "default"
#  }
#
#  subject {
#    kind      = "Group"  # Use "Group" if you have mapped an IAM role
#    name      = "arn:aws:iam::{{account}}:role/tf-validate-project-codepipeline-role"
#    api_group = "rbac.authorization.k8s.io"
#  }
#
#  role_ref {
#    kind      = "Role"
#    name      = kubernetes_role.configmap_reader.metadata[0].name
#    api_group = "rbac.authorization.k8s.io"
#  }
#}
#
#
#resource "kubernetes_role" "configmap_reader" {
#  metadata {
#    name      = "configmap-reader"
#     namespace = "default"
#  }
#
#  rule {
#    api_groups = [""]
#    resources  = ["configmaps"]
#    verbs      = ["get", "list", "watch"]
#  }
#}
#