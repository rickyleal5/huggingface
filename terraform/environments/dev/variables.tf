variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "name_prefix" {
  description = "Prefix to be used for all resource names"
  type        = string
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "managed_by" {
  description = "Managed by"
  type        = string
  default     = "Terraform"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "huggingface-dev"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.32"
}

variable "eks_node_groups" {
  description = "Map of EKS node groups"
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
  }))
  default = {
    default = {
      instance_types = ["t3.large"]
      min_size       = 2
      max_size       = 5
      desired_size   = 3
      disk_size      = 20
    }
  }
}

variable "ecr_repositories" {
  description = "List of ECR repositories to create"
  type        = list(string)
  default     = ["api-gateway", "gpt2-model-server"]
}

variable "admin_users" {
  description = "List of IAM users to be added to admin group"
  type        = list(string)
  default     = []
}

variable "developer_users" {
  description = "List of IAM users to be added to developer group"
  type        = list(string)
  default     = []
}

variable "alert_email" {
  description = "Email address for receiving alerts"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_logs_retention" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"] # Restrict this in production
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
  default     = ""
}

variable "cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL for the EKS cluster"
  type        = string
  default     = ""
}

variable "cluster_oidc_thumbprint" {
  description = "The thumbprint of the OIDC issuer certificate"
  type        = string
  default     = ""
}

variable "waf_rate_limit" {
  description = "Rate limit for the WAF rule"
  type        = number
  default     = 100
}

variable "aws_access_key" {
  description = "AWS access key for local testing"
  type        = string
  default     = null
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key for local testing"
  type        = string
  default     = null
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS session token for local testing"
  type        = string
  default     = null
  sensitive   = true
}
