variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix to be used for all resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "alerts_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
  default     = "" # Make it optional
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
  default     = ""
}

variable "api_gateway_security_group_id" {
  description = "Security group ID for the API Gateway VPC Link"
  type        = string
}

variable "empty_placeholder" {
  default = ""
}
