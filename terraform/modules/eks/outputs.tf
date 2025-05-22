output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = var.eks_cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "ARN of the IAM role used by the EKS cluster"
  value       = var.eks_cluster_role_arn
}

output "node_iam_role_arn" {
  description = "ARN of the IAM role used by the EKS nodes"
  value       = var.eks_node_role_arn
}

output "node_group_id" {
  description = "ID of the EKS node group"
  value       = aws_eks_node_group.this.id
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.this.arn
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_certificate_authority_data" {
  description = "The base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_oidc_thumbprint" {
  description = "The thumbprint of the OIDC issuer certificate"
  value       = data.tls_certificate.eks.certificates[0].sha1_fingerprint
}

output "node_group_name" {
  description = "The name of the EKS node group"
  value       = aws_eks_node_group.this.node_group_name
}

output "node_group_role_arn" {
  description = "The ARN of the IAM role for the EKS node group"
  value       = var.eks_node_role_arn
}

output "cluster" {
  description = "The EKS cluster"
  value       = aws_eks_cluster.this
}
