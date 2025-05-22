output "admin_group_name" {
  description = "Name of the admin IAM group"
  value       = aws_iam_group.admin.name
}

output "developer_group_name" {
  description = "Name of the developer IAM group"
  value       = aws_iam_group.developer.name
}

output "admin_policy_arn" {
  description = "ARN of the admin IAM policy"
  value       = aws_iam_policy.admin.arn
}

output "developer_policy_arn" {
  description = "ARN of the developer IAM policy"
  value       = aws_iam_policy.developer.arn
}

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node role"
  value       = aws_iam_role.eks_node.arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller role"
  value       = var.cluster_oidc_issuer_url != "" ? aws_iam_role.aws_load_balancer_controller[0].arn : ""
}

output "flow_logs_role_arn" {
  description = "ARN of the VPC Flow Logs role"
  value       = var.enable_flow_logs ? aws_iam_role.flow_logs[0].arn : null
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = var.cluster_oidc_issuer_url != "" ? aws_iam_openid_connect_provider.eks[0].arn : null
} 