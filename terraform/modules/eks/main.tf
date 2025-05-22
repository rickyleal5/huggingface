# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = "${var.name_prefix}-cluster"
  role_arn = var.eks_cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"] # TODO: Replace with specific IP ranges in production
    security_group_ids      = [var.eks_cluster_security_group_id]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_cloudwatch_log_group.cluster
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-cluster"
    }
  )
}

# EKS Node Group
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name_prefix}-node-group"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.node_instance_types

  launch_template {
    name    = aws_launch_template.eks_node.name
    version = aws_launch_template.eks_node.latest_version
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-node-group"
    }
  )

  depends_on = [
    aws_launch_template.eks_node
  ]
}

# Launch Template for EKS Node
resource "aws_launch_template" "eks_node" {
  name = "${var.name_prefix}-node-launch-template"

  vpc_security_group_ids = [var.eks_worker_node_security_group_id]

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.name_prefix}-node"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-node-launch-template"
    }
  )
}

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.name_prefix}/cluster"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eks-logs"
    }
  )
}

# Get the OIDC certificate thumbprint
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}



