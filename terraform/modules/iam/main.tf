#######################
# IAM Users and Groups
#######################

# IAM Groups
resource "aws_iam_group" "admin" {
  name = "${var.name_prefix}-admin-group"
  path = "/${var.name_prefix}/"
}

resource "aws_iam_group" "developer" {
  name = "${var.name_prefix}-developer-group"
  path = "/${var.name_prefix}/"
}

# IAM Users
resource "aws_iam_user" "admin" {
  count = length(var.admin_users)
  name  = var.admin_users[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-admin-user-${count.index + 1}"
    }
  )
}

resource "aws_iam_user" "developer" {
  count = length(var.developer_users)
  name  = var.developer_users[count.index]

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-developer-user-${count.index + 1}"
    }
  )
}

# Group Memberships
resource "aws_iam_user_group_membership" "admin" {
  count  = length(var.admin_users)
  user   = aws_iam_user.admin[count.index].name
  groups = [aws_iam_group.admin.name]
}

resource "aws_iam_user_group_membership" "developer" {
  count  = length(var.developer_users)
  user   = aws_iam_user.developer[count.index].name
  groups = [aws_iam_group.developer.name]
}

# IAM Policies
resource "aws_iam_policy" "admin" {
  name        = "${var.name_prefix}-admin-policy"
  description = "Admin policy for ${var.name_prefix}"
  path        = "/${var.name_prefix}/"
  policy      = data.aws_iam_policy_document.admin.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-admin-policy"
    }
  )
}

resource "aws_iam_policy" "developer" {
  name        = "${var.name_prefix}-developer-policy"
  description = "Developer policy for ${var.name_prefix}"
  path        = "/${var.name_prefix}/"
  policy      = data.aws_iam_policy_document.developer.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-developer-policy"
    }
  )
}

# Policy Documents
data "aws_iam_policy_document" "admin" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:*",
      "eks:*",
      "s3:*",
      "cloudwatch:*",
      "logs:*",
      "iam:Get*",
      "iam:List*",
      "iam:PassRole",
      "wafv2:*",
      "waf:*"
    ]
    resources = [
      "arn:aws:ecr:${var.region}:${var.aws_account_id}:repository/${var.name_prefix}/*",
      "arn:aws:eks:${var.region}:${var.aws_account_id}:cluster/${var.name_prefix}*",
      "arn:aws:cloudwatch:${var.region}:${var.aws_account_id}:*",
      "arn:aws:logs:${var.region}:${var.aws_account_id}:log-group:/${var.name_prefix}/*",
      "arn:aws:iam::${var.aws_account_id}:role/${var.name_prefix}*",
      "arn:aws:wafv2:${var.region}:${var.aws_account_id}:*/*/*",
      "arn:aws:wafv2:${var.region}:${var.aws_account_id}:*/*/*/*"
    ]
  }
}

data "aws_iam_policy_document" "developer" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "eks:DescribeCluster",
      "eks:ListClusters",
      "cloudwatch:GetMetricStatistics",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]
    resources = [
      "arn:aws:ecr:${var.region}:${var.aws_account_id}:repository/${var.name_prefix}/*",
      "arn:aws:eks:${var.region}:${var.aws_account_id}:cluster/${var.name_prefix}*",
      "arn:aws:cloudwatch:${var.region}:${var.aws_account_id}:*",
      "arn:aws:logs:${var.region}:${var.aws_account_id}:log-group:/${var.name_prefix}/*"
    ]
  }
}

# Policy Attachments
resource "aws_iam_group_policy_attachment" "admin" {
  group      = aws_iam_group.admin.name
  policy_arn = aws_iam_policy.admin.arn

}

resource "aws_iam_group_policy_attachment" "developer" {
  group      = aws_iam_group.developer.name
  policy_arn = aws_iam_policy.developer.arn

}

#######################
# EKS Related Resources
#######################

# EKS Cluster Role
resource "aws_iam_role" "eks_cluster" {
  name = "${var.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eks-cluster-role"
    }
  )
}

# EKS Node Role
resource "aws_iam_role" "eks_node" {
  name = "${var.name_prefix}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eks-node-role"
    }
  )
}

# EKS Cluster Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# EKS Node Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_node" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# OIDC Provider for EKS
resource "aws_iam_openid_connect_provider" "eks" {
  count           = var.cluster_oidc_issuer_url != "" ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.cluster_oidc_thumbprint]
  url             = var.cluster_oidc_issuer_url

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-oidc-provider"
    }
  )
}

#######################
# ALB Related Resources
#######################

# AWS Load Balancer Controller Policy
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.name_prefix}-aws-load-balancer-controller"
  description = "Policy for AWS Load Balancer Controller"
  policy      = data.aws_iam_policy_document.aws_load_balancer_controller.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-aws-load-balancer-controller-policy"
    }
  )
}

# AWS Load Balancer Controller Policy Document
data "aws_iam_policy_document" "aws_load_balancer_controller" {
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:Describe*",
      "elasticloadbalancing:*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

# AWS Load Balancer Controller Role
resource "aws_iam_role" "aws_load_balancer_controller" {
  count = var.cluster_oidc_issuer_url != "" ? 1 : 0
  name  = "${var.name_prefix}-aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${replace(var.cluster_oidc_issuer_url, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-aws-load-balancer-controller-role"
    }
  )
}

# AWS Load Balancer Controller Policy Attachment
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  count      = var.cluster_oidc_issuer_url != "" ? 1 : 0
  role       = aws_iam_role.aws_load_balancer_controller[0].name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

#######################
# VPC Related Resources
#######################

# VPC Flow Logs Role
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.name_prefix}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-flow-logs-role"
    }
  )
}

# VPC Flow Logs Policy
resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.name_prefix}-flow-logs"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })

} 