output "api_gateway_security_group_id" {
  description = "ID of the API Gateway security group"
  value       = aws_security_group.api_gateway.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = aws_security_group.eks_cluster.id
}

output "eks_worker_node_security_group_id" {
  description = "ID of the EKS worker node security group"
  value       = aws_security_group.eks_worker_nodes.id
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the VPC endpoints security group"
  value       = aws_security_group.vpc_endpoints.id
} 