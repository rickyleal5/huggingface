output "model_server_log_group" {
  description = "Name of the CloudWatch log group for model server"
  value       = aws_cloudwatch_log_group.model_server.name
}

output "api_gateway_log_group" {
  description = "Name of the CloudWatch log group for API gateway"
  value       = aws_cloudwatch_log_group.api_gateway.name
}

output "alerts_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

# output "prometheus_role_arn" {
#   description = "ARN of the IAM role for Prometheus"
#   value       = aws_iam_role.prometheus.arn
# } 