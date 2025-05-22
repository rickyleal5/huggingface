output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "model_server_repository_url" {
  description = "URL of the model server ECR repository"
  value       = module.ecr.model_server_repository_url
}

output "api_gateway_repository_url" {
  description = "URL of the API gateway ECR repository"
  value       = module.ecr.api_gateway_repository_url
}

output "api_gateway_endpoint" {
  description = "Endpoint of the API Gateway"
  value       = module.api_gateway.stage_endpoint
}

output "load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = module.iam.aws_load_balancer_controller_role_arn
}

output "api_gateway_security_group_id" {
  description = "ID of the API Gateway security group"
  value       = module.security_groups.api_gateway_security_group_id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security_groups.alb_security_group_id
}

output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = module.security_groups.eks_cluster_security_group_id
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cloudfront.distribution_domain_name
}