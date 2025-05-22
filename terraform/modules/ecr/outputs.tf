output "model_server_repository_url" {
  description = "URL of the model server ECR repository"
  value       = aws_ecr_repository.model_server.repository_url
}

output "api_gateway_repository_url" {
  description = "URL of the API gateway ECR repository"
  value       = aws_ecr_repository.api_gateway.repository_url
} 